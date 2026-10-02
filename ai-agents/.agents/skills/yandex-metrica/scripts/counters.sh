#!/bin/bash
# Manage Yandex Metrica counters

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_config

ACTION=""
COUNTER_ID=""
SEARCH=""
PER_PAGE="100"
FAVORITE=""

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --action|-a) ACTION="$2"; shift 2 ;;
        --counter|-c) COUNTER_ID="$2"; shift 2 ;;
        --search|-s) SEARCH="$2"; shift 2 ;;
        --per-page) PER_PAGE="$2"; shift 2 ;;
        --favorite) FAVORITE="true"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$ACTION" ]]; then
    echo "Usage: counters.sh --action <list|get|info> [options]"
    echo ""
    echo "Actions:"
    echo "  list    List all counters"
    echo "  get     Get counter details (requires --counter)"
    echo "  info    Get counter with goals and filters (requires --counter)"
    echo ""
    echo "Options:"
    echo "  --counter, -c   Counter ID"
    echo "  --search, -s    Filter counters by name/site"
    echo "  --per-page      Results per page (default: 100)"
    echo "  --favorite       Show only favorite counters"
    exit 1
fi

case "$ACTION" in
    list)
        query="?per_page=$PER_PAGE"
        if [[ -n "$SEARCH" ]]; then
            query+="&search_string=$(urlencode "$SEARCH")"
        fi
        if [[ "$FAVORITE" == "true" ]]; then
            query+="&favorite=true"
        fi

        response=$(metrica_get "/management/v1/counters" "$query")

        if command -v jq &>/dev/null; then
            total=$(echo "$response" | jq '.rows')
            echo "Total counters: $total"
            echo ""
            echo "$response" | jq -r '.counters[] | "\(.id)\t\(.name)\t\(.site)\t\(.status)"' | \
                column -t -s $'\t'
        else
            echo "$response"
        fi
        ;;

    get)
        if [[ -z "$COUNTER_ID" ]]; then
            echo "Error: --counter required for 'get' action"
            exit 1
        fi

        response=$(metrica_get "/management/v1/counter/$COUNTER_ID")
        echo "$response" | format_json
        ;;

    info)
        if [[ -z "$COUNTER_ID" ]]; then
            echo "Error: --counter required for 'info' action"
            exit 1
        fi

        echo "=== Counter Info ==="
        response=$(metrica_get "/management/v1/counter/$COUNTER_ID")
        if command -v jq &>/dev/null; then
            echo "$response" | jq '{id, name, site, status, create_time, code_status}'
        else
            echo "$response"
        fi

        echo ""
        echo "=== Goals ==="
        goals=$(metrica_get "/management/v1/counter/$COUNTER_ID/goals")
        if command -v jq &>/dev/null; then
            echo "$goals" | jq -r '.goals[] | "\(.id)\t\(.name)\t\(.type)"' 2>/dev/null | \
                column -t -s $'\t' || echo "(no goals)"
        else
            echo "$goals"
        fi

        echo ""
        echo "=== Filters ==="
        filters=$(metrica_get "/management/v1/counter/$COUNTER_ID/filters")
        if command -v jq &>/dev/null; then
            echo "$filters" | jq -r '.filters[] | "\(.id)\t\(.attr)\t\(.type)\t\(.value)"' 2>/dev/null | \
                column -t -s $'\t' || echo "(no filters)"
        else
            echo "$filters"
        fi
        ;;

    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
