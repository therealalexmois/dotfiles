#!/bin/bash
# Check Yandex Metrica API connection

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_config

echo "Checking Metrica API connection..."
echo ""

# Test with counters list
response=$(metrica_get "/management/v1/counters" "?per_page=1")

if echo "$response" | grep -q '"counters"'; then
    echo "Metrica API: OK"
    echo ""

    # Extract total counters count
    total=$(json_value "$response" "rows")
    echo "Available counters: $total"

    # Show first counter if available
    if [[ "$total" -gt 0 ]]; then
        echo ""
        echo "First counter:"
        if command -v jq &>/dev/null; then
            echo "$response" | jq '.counters[0] | {id, name, site}'
        else
            echo "$response" | grep -o '"id":[0-9]*' | head -1
        fi
    fi
else
    echo "Metrica API: Error"
    echo "$response"
    exit 1
fi

echo ""
echo "=== Available API endpoints ==="
echo "- Management API: counters, goals, filters, segments, grants"
echo "- Reporting API:  /stat/v1/data, /data/bytime, /data/drilldown"
echo "- Logs API:       raw visits and hits export"
echo ""
echo "Token is valid and API is accessible."
