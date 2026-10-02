#!/bin/bash
# Get Yandex Metrica statistics (Reporting API)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_config

COUNTER_ID="${YANDEX_METRICA_COUNTER_ID:-}"
METRICS="ym:s:visits,ym:s:pageviews,ym:s:users"
DIMENSIONS=""
DATE1=""
DATE2=""
FILTERS=""
SORT=""
LIMIT="100"
ACCURACY="full"
REPORT_TYPE="data"
CSV_FILE=""
PRESET=""

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --counter|-c) COUNTER_ID="$2"; shift 2 ;;
        --metrics|-m) METRICS="$2"; shift 2 ;;
        --dimensions|-d) DIMENSIONS="$2"; shift 2 ;;
        --date1) DATE1="$2"; shift 2 ;;
        --date2) DATE2="$2"; shift 2 ;;
        --filters|-f) FILTERS="$2"; shift 2 ;;
        --sort|-s) SORT="$2"; shift 2 ;;
        --limit|-l) LIMIT="$2"; shift 2 ;;
        --accuracy) ACCURACY="$2"; shift 2 ;;
        --type|-t) REPORT_TYPE="$2"; shift 2 ;;
        --csv) CSV_FILE="$2"; shift 2 ;;
        --preset) PRESET="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$COUNTER_ID" ]]; then
    echo "Usage: stats.sh --counter <ID> [options]"
    echo ""
    echo "Options:"
    echo "  --counter, -c     Counter ID (required, or set YANDEX_METRICA_COUNTER_ID)"
    echo "  --metrics, -m     Metrics (default: ym:s:visits,ym:s:pageviews,ym:s:users)"
    echo "  --dimensions, -d  Dimensions (e.g. ym:s:trafficSource)"
    echo "  --date1           Start date (YYYY-MM-DD, default: 30 days ago)"
    echo "  --date2           End date (YYYY-MM-DD, default: today)"
    echo "  --filters, -f     Filters (e.g. ym:s:trafficSource=='organic')"
    echo "  --sort, -s        Sort field (prefix with - for desc)"
    echo "  --limit, -l       Max rows (default: 100)"
    echo "  --accuracy        Sampling: full, medium, low (default: full)"
    echo "  --type, -t        Report type: data, bytime, drilldown, comparison"
    echo "  --csv             Export to CSV file"
    echo "  --preset          Use preset: traffic, sources, geo, content, technology"
    echo ""
    echo "Common presets:"
    echo "  traffic    - visits, pageviews, users, bounceRate, avgVisitDuration"
    echo "  sources    - traffic sources breakdown"
    echo "  geo        - visits by country/city"
    echo "  content    - top pages"
    echo "  technology - browsers, OS, devices"
    exit 1
fi

# Set defaults
if [[ -z "$DATE1" ]]; then
    DATE1=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d)
fi
if [[ -z "$DATE2" ]]; then
    DATE2=$(date +%Y-%m-%d)
fi

# Apply presets
case "$PRESET" in
    traffic)
        METRICS="ym:s:visits,ym:s:pageviews,ym:s:users,ym:s:bounceRate,ym:s:pageDepth,ym:s:avgVisitDurationSeconds"
        ;;
    sources)
        METRICS="ym:s:visits,ym:s:users,ym:s:bounceRate,ym:s:pageDepth"
        DIMENSIONS="ym:s:lastTrafficSource"
        SORT="-ym:s:visits"
        ;;
    geo)
        METRICS="ym:s:visits,ym:s:users"
        DIMENSIONS="ym:s:regionCountry,ym:s:regionCity"
        SORT="-ym:s:visits"
        ;;
    content)
        METRICS="ym:s:visits,ym:s:pageviews,ym:s:bounceRate"
        DIMENSIONS="ym:s:startURL"
        SORT="-ym:s:pageviews"
        ;;
    technology)
        METRICS="ym:s:visits,ym:s:users"
        DIMENSIONS="ym:s:browser"
        SORT="-ym:s:visits"
        ;;
esac

# Build query
params=("ids=$COUNTER_ID" "metrics=$METRICS" "date1=$DATE1" "date2=$DATE2" "limit=$LIMIT" "accuracy=$ACCURACY")

if [[ -n "$DIMENSIONS" ]]; then
    params+=("dimensions=$DIMENSIONS")
fi
if [[ -n "$FILTERS" ]]; then
    params+=("filters=$(urlencode "$FILTERS")")
fi
if [[ -n "$SORT" ]]; then
    params+=("sort=$SORT")
fi

query=$(build_query "${params[@]}")

# Make request
endpoint="/stat/v1/$REPORT_TYPE"
response=$(stat_get "$endpoint" "$query")

# Check for error
if echo "$response" | grep -q '"errors"'; then
    echo "Error:"
    echo "$response" | format_json
    exit 1
fi

# Output
if [[ -n "$CSV_FILE" ]]; then
    if command -v jq &>/dev/null; then
        # Extract headers
        headers=$(echo "$response" | jq -r '[.query.dimensions[], .query.metrics[]] | join(";")')
        echo "$headers" > "$CSV_FILE"

        # Extract data rows
        echo "$response" | jq -r '.data[] | [(.dimensions[]?.name // ""), (.metrics[][] | tostring)] | join(";")' >> "$CSV_FILE"

        rows=$(wc -l < "$CSV_FILE")
        echo "Exported $((rows - 1)) rows to: $CSV_FILE"
    else
        echo "$response" > "$CSV_FILE"
        echo "Raw JSON saved to: $CSV_FILE"
    fi
else
    if command -v jq &>/dev/null; then
        # Summary
        total_rows=$(echo "$response" | jq '.total_rows')
        sampled=$(echo "$response" | jq '.sampled')
        echo "Period: $DATE1 — $DATE2"
        echo "Rows: $total_rows | Sampled: $sampled"
        echo ""

        # Totals
        echo "=== Totals ==="
        echo "$response" | jq -r '[.query.metrics, .totals] | transpose[] | "\(.[0]) = \(.[1])"' 2>/dev/null || true
        echo ""

        # Data
        echo "=== Data ==="
        echo "$response" | jq '.data[:20]'
    else
        echo "$response"
    fi
fi
