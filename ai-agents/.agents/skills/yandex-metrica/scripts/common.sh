#!/bin/bash
# Common functions for Yandex Metrica API

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/.env"
CACHE_DIR="$SCRIPT_DIR/../cache"
METRICA_API="https://api-metrika.yandex.net"

# Load config
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    fi

    if [[ -z "$YANDEX_METRICA_TOKEN" ]]; then
        echo "Error: YANDEX_METRICA_TOKEN not found."
        echo "Set in config/.env or environment. See config/README.md for instructions."
        exit 1
    fi
}

# GET request to Metrica API
# Usage: metrica_get "/management/v1/counters" "?field=goals"
metrica_get() {
    local endpoint="$1"
    local query="${2:-}"

    curl -s -X GET "${METRICA_API}${endpoint}${query}" \
        -H "Authorization: OAuth $YANDEX_METRICA_TOKEN" \
        -H "Accept: application/json"
}

# POST request to Metrica API
# Usage: metrica_post "/management/v1/counter" '{"site":"example.com"}'
metrica_post() {
    local endpoint="$1"
    local body="$2"

    curl -s -X POST "${METRICA_API}${endpoint}" \
        -H "Authorization: OAuth $YANDEX_METRICA_TOKEN" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$body"
}

# PUT request to Metrica API
metrica_put() {
    local endpoint="$1"
    local body="$2"

    curl -s -X PUT "${METRICA_API}${endpoint}" \
        -H "Authorization: OAuth $YANDEX_METRICA_TOKEN" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$body"
}

# DELETE request to Metrica API
metrica_delete() {
    local endpoint="$1"

    curl -s -X DELETE "${METRICA_API}${endpoint}" \
        -H "Authorization: OAuth $YANDEX_METRICA_TOKEN" \
        -H "Accept: application/json"
}

# Reporting API request (stat data)
# Usage: stat_get "/stat/v1/data" "?ids=12345&metrics=ym:s:visits&date1=2025-01-01&date2=2025-01-31"
stat_get() {
    local endpoint="$1"
    local query="$2"

    curl -s -X GET "${METRICA_API}${endpoint}${query}" \
        -H "Authorization: OAuth $YANDEX_METRICA_TOKEN" \
        -H "Accept: application/json"
}

# Format JSON output (pretty print if jq available)
format_json() {
    if command -v jq &>/dev/null; then
        jq '.'
    else
        cat
    fi
}

# Extract JSON value using grep/sed (no jq dependency)
json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":[^,}]*" | head -1 | sed 's/.*://' | tr -d '"[:space:]'
}

# Format number with thousands separator
format_number() {
    local num="$1"
    printf "%'d" "$num" 2>/dev/null || echo "$num"
}

# URL-encode a string
urlencode() {
    local str="$1"
    python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=''))" "$str"
}

# Build query string from associative params
# Usage: build_query "ids=123" "metrics=ym:s:visits" "date1=2025-01-01"
build_query() {
    local query="?"
    local first=true
    for param in "$@"; do
        if [[ "$first" == true ]]; then
            query+="$param"
            first=false
        else
            query+="&$param"
        fi
    done
    echo "$query"
}
