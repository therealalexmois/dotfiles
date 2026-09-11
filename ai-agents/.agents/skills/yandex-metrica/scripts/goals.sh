#!/bin/bash
# Manage Yandex Metrica goals

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_config

ACTION=""
COUNTER_ID="${YANDEX_METRICA_COUNTER_ID:-}"
GOAL_ID=""

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --action|-a) ACTION="$2"; shift 2 ;;
        --counter|-c) COUNTER_ID="$2"; shift 2 ;;
        --goal-id|-g) GOAL_ID="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$ACTION" || -z "$COUNTER_ID" ]]; then
    echo "Usage: goals.sh --action <list|get> --counter <ID> [options]"
    echo ""
    echo "Actions:"
    echo "  list    List all goals for a counter"
    echo "  get     Get goal details (requires --goal-id)"
    echo ""
    echo "Goal types in Metrica:"
    echo "  url       - Page visit goal"
    echo "  action    - Event/JavaScript goal"
    echo "  step      - Multi-step (composite) goal"
    echo "  phone     - Phone number goal"
    echo "  email     - Email goal"
    echo "  form      - Form submission goal"
    echo "  messenger - Messenger click goal"
    exit 1
fi

BASE="/management/v1/counter/$COUNTER_ID"

case "$ACTION" in
    list)
        response=$(metrica_get "$BASE/goals")

        if command -v jq &>/dev/null; then
            echo "$response" | jq -r '.goals[] | "\(.id)\t\(.name)\t\(.type)\t\(.is_retargeting)"' | \
                column -t -s $'\t'
        else
            echo "$response"
        fi
        ;;

    get)
        if [[ -z "$GOAL_ID" ]]; then
            echo "Error: --goal-id required for 'get' action"
            exit 1
        fi

        response=$(metrica_get "$BASE/goal/$GOAL_ID")
        echo "$response" | format_json
        ;;

    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
