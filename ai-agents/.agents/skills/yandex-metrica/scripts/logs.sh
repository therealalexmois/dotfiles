#!/bin/bash
# Yandex Metrica Logs API — create, check, download, clean log requests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_config

ACTION=""
COUNTER_ID="${YANDEX_METRICA_COUNTER_ID:-}"
REQUEST_ID=""
SOURCE="visits"
DATE1=""
DATE2=""
FIELDS=""
OUTPUT_DIR="."

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --action|-a) ACTION="$2"; shift 2 ;;
        --counter|-c) COUNTER_ID="$2"; shift 2 ;;
        --request-id|-r) REQUEST_ID="$2"; shift 2 ;;
        --source|-s) SOURCE="$2"; shift 2 ;;
        --date1) DATE1="$2"; shift 2 ;;
        --date2) DATE2="$2"; shift 2 ;;
        --fields|-f) FIELDS="$2"; shift 2 ;;
        --output|-o) OUTPUT_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$ACTION" || -z "$COUNTER_ID" ]]; then
    echo "Usage: logs.sh --action <action> --counter <ID> [options]"
    echo ""
    echo "Actions:"
    echo "  evaluate  Check if log request is possible"
    echo "  create    Create a new log request"
    echo "  list      List all log requests"
    echo "  status    Check status of a log request (requires --request-id)"
    echo "  download  Download log parts (requires --request-id)"
    echo "  clean     Clean (delete) a log request (requires --request-id)"
    echo ""
    echo "Options:"
    echo "  --counter, -c      Counter ID (required)"
    echo "  --request-id, -r   Log request ID (for status/download/clean)"
    echo "  --source, -s       Source: visits or hits (default: visits)"
    echo "  --date1            Start date YYYY-MM-DD"
    echo "  --date2            End date YYYY-MM-DD"
    echo "  --fields, -f       Comma-separated field list"
    echo "  --output, -o       Output directory for downloads (default: .)"
    echo ""
    echo "Common visit fields:"
    echo "  ym:s:visitID, ym:s:dateTime, ym:s:clientID, ym:s:startURL,"
    echo "  ym:s:lastTrafficSource, ym:s:lastSearchPhrase, ym:s:regionCity,"
    echo "  ym:s:deviceCategory, ym:s:browser, ym:s:operatingSystem"
    echo ""
    echo "Common hit fields:"
    echo "  ym:pv:watchID, ym:pv:dateTime, ym:pv:clientID, ym:pv:URL,"
    echo "  ym:pv:title, ym:pv:referer, ym:pv:UTMSource, ym:pv:UTMMedium"
    exit 1
fi

BASE="/management/v1/counter/$COUNTER_ID"

case "$ACTION" in
    evaluate)
        if [[ -z "$DATE1" || -z "$DATE2" ]]; then
            echo "Error: --date1 and --date2 required for evaluate"
            exit 1
        fi

        query="?date1=$DATE1&date2=$DATE2&source=$SOURCE"
        if [[ -n "$FIELDS" ]]; then
            query+="&fields=$FIELDS"
        fi

        response=$(metrica_get "$BASE/logrequests/evaluate" "$query")

        if command -v jq &>/dev/null; then
            echo "$response" | jq '{
                possible: .log_request_evaluation.possible,
                max_possible_day_quantity: .log_request_evaluation.max_possible_day_quantity
            }'
        else
            echo "$response"
        fi
        ;;

    create)
        if [[ -z "$DATE1" || -z "$DATE2" ]]; then
            echo "Error: --date1 and --date2 required for create"
            exit 1
        fi

        query="?date1=$DATE1&date2=$DATE2&source=$SOURCE"
        if [[ -n "$FIELDS" ]]; then
            query+="&fields=$FIELDS"
        fi

        # Logs API create requires query params in URL, not body
        response=$(curl -s -X POST "${METRICA_API}${BASE}/logrequests${query}" \
            -H "Authorization: OAuth $YANDEX_METRICA_TOKEN" \
            -H "Accept: application/json")

        if command -v jq &>/dev/null; then
            request_id=$(echo "$response" | jq -r '.log_request.request_id')
            status=$(echo "$response" | jq -r '.log_request.status')
            echo "Created log request: $request_id (status: $status)"
            echo ""
            echo "Check status: bash scripts/logs.sh --action status --counter $COUNTER_ID --request-id $request_id"
        else
            echo "$response"
        fi
        ;;

    list)
        response=$(metrica_get "$BASE/logrequests")

        if command -v jq &>/dev/null; then
            echo "$response" | jq -r '.requests[] | "\(.request_id)\t\(.source)\t\(.status)\t\(.date1) — \(.date2)"' | \
                column -t -s $'\t'
        else
            echo "$response"
        fi
        ;;

    status)
        if [[ -z "$REQUEST_ID" ]]; then
            echo "Error: --request-id required for status"
            exit 1
        fi

        response=$(metrica_get "$BASE/logrequest/$REQUEST_ID")

        if command -v jq &>/dev/null; then
            echo "$response" | jq '{
                request_id: .log_request.request_id,
                status: .log_request.status,
                source: .log_request.source,
                date1: .log_request.date1,
                date2: .log_request.date2,
                size: .log_request.size,
                parts: (.log_request.parts | length)
            }'
        else
            echo "$response"
        fi
        ;;

    download)
        if [[ -z "$REQUEST_ID" ]]; then
            echo "Error: --request-id required for download"
            exit 1
        fi

        if ! command -v jq &>/dev/null; then
            echo "Error: jq is required for the download action"
            exit 1
        fi

        # Get request info to find parts
        response=$(metrica_get "$BASE/logrequest/$REQUEST_ID")
        status=$(echo "$response" | jq -r '.log_request.status' 2>/dev/null)

        if [[ "$status" != "processed" ]]; then
            echo "Error: Log request not ready (status: $status)"
            echo "Wait for 'processed' status."
            exit 1
        fi

        parts=$(echo "$response" | jq '.log_request.parts | length')
        echo "Downloading $parts part(s) to $OUTPUT_DIR..."

        mkdir -p "$OUTPUT_DIR"
        for ((i=0; i<parts; i++)); do
            output_file="$OUTPUT_DIR/log_${COUNTER_ID}_${REQUEST_ID}_part${i}.tsv"
            curl -s -o "$output_file" \
                -H "Authorization: OAuth $YANDEX_METRICA_TOKEN" \
                "${METRICA_API}${BASE}/logrequest/$REQUEST_ID/part/$i/download"
            size=$(wc -c < "$output_file" | tr -d ' ')
            echo "  Part $i: $(format_number "$size") bytes → $output_file"
        done

        echo "Done."
        ;;

    clean)
        if [[ -z "$REQUEST_ID" ]]; then
            echo "Error: --request-id required for clean"
            exit 1
        fi

        response=$(curl -s -X POST "${METRICA_API}${BASE}/logrequest/$REQUEST_ID/clean" \
            -H "Authorization: OAuth $YANDEX_METRICA_TOKEN" \
            -H "Accept: application/json")
        echo "Cleaned log request $REQUEST_ID"
        ;;

    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
