#!/usr/bin/env bash
# Post-release smoke and sanity checks for dwsai-data-agent (prod, Spirit Deploy / DaaS).
# Read-only. Verifies the new release is serving on all clusters and introduced no NEW
# Sage ERROR signatures vs the previous release (regression check, not raw ERROR count).
#
# Usage:
#   RELEASE_TAG=release-260604.2203 ./release_smoke.sh [PREV_TAG]
# Optional env overrides:
#   TENANT APP DEPLOY NS CLUSTERS SAGE_GROUP SAGE_SYSTEM SAGE_ENV
#   WINDOW_HOURS BASELINE_HOURS MAX_RESTARTS REPO PARAMS_FILE
#
# Exit: 0 = PASS, 1 = FAIL (review output), 2 = usage/precondition error.
set -uo pipefail

RELEASE_TAG="${RELEASE_TAG:-${1:-}}"
PREV_TAG="${PREV_TAG:-${2:-}}"
REPO="${REPO:-.}"

TENANT="${TENANT:-dwsai}"
APP="${APP:-data-agent-prod}"
DEPLOY="${DEPLOY:-data-agent-webservice-prod}"
NS="${NS:-dwsai-data-agent-prod-prod-daas}"
CLUSTERS="${CLUSTERS:-bm-ix-m5-inside-wl1.prod,bm-ix-m5-inside-wl4.prod}"
SAGE_GROUP="${SAGE_GROUP:-dwsai}"
SAGE_SYSTEM="${SAGE_SYSTEM:-data-agent}"
SAGE_ENV="${SAGE_ENV:-prod}"
WINDOW_HOURS="${WINDOW_HOURS:-1}"
BASELINE_HOURS="${BASELINE_HOURS:-24}"
MAX_RESTARTS="${MAX_RESTARTS:-0}"
PARAMS_FILE="${PARAMS_FILE:-src/app/infrastructure/remote_config/params.py}"

fail=0
pass() { printf '  [PASS] %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; fail=1; }
warn() { printf '  [WARN] %s\n' "$*"; }

[ -n "$RELEASE_TAG" ] || { echo "usage: RELEASE_TAG=release-YYMMDD.HHMM $0 [PREV_TAG]" >&2; exit 2; }
command -v dp  >/dev/null || { echo "dp CLI not found" >&2; exit 2; }
command -v jq  >/dev/null || { echo "jq required" >&2; exit 2; }

strip_banner() { grep -vE 'dp update available|please run: dp update'; }

echo "Post-release smoke: $RELEASE_TAG  (ns=$NS, clusters=$CLUSTERS)"

# Resolve previous release tag if not provided.
if [ -z "$PREV_TAG" ]; then
  PREV_TAG=$(git -C "$REPO" tag -l 'release-*' --sort=-version:refname 2>/dev/null \
             | grep -A1 -x "$RELEASE_TAG" | tail -1)
fi
[ -n "$PREV_TAG" ] && echo "Previous release: $PREV_TAG" || warn "previous release tag not resolved"

# --- 1) Pods / image / readiness / restarts across all clusters (dpKube) ---
echo "[1] pods/image/health (dpKube)"
J=$(dp kube get logs -n "$NS" -e "$SAGE_ENV" -c "$CLUSTERS" -l 1 2>/dev/null | strip_banner)
total=$(printf '%s' "$J" | jq '[.clusters[]?.pods[]?.containers[]?] | length' 2>/dev/null || echo 0)
if [ "${total:-0}" -gt 0 ]; then
  onrel=$(printf '%s' "$J" | jq --arg t ":$RELEASE_TAG" '[.clusters[].pods[].containers[] | select(.image|endswith($t))] | length')
  notready=$(printf '%s' "$J" | jq '[.clusters[].pods[].containers[] | select(.ready!=true)] | length')
  maxre=$(printf '%s' "$J" | jq '[.clusters[].pods[].containers[].restarts] | max')
  [ "$onrel" = "$total" ] && pass "image: $onrel/$total containers on $RELEASE_TAG" \
                          || bad  "image: $onrel/$total containers on $RELEASE_TAG (expected all)"
  [ "$notready" = 0 ] && pass "readiness: $total/$total ready (startup/readiness/liveness green)" \
                      || bad  "readiness: $notready container(s) not ready"
  [ "${maxre:-0}" -le "$MAX_RESTARTS" ] && pass "restarts: max=$maxre (<= $MAX_RESTARTS)" \
                                        || bad  "restarts: max=$maxre (> $MAX_RESTARTS)"
else
  bad "dpKube returned no containers (check clusters/namespace/auth)"
fi

# --- 2) New feature flags must be verified in thermostat ---
echo "[2] feature flags (new release.* keys)"
if [ -n "$PREV_TAG" ] && git -C "$REPO" rev-parse "$PREV_TAG" >/dev/null 2>&1; then
  newflags=$(git -C "$REPO" diff "$PREV_TAG..$RELEASE_TAG" -- "$PARAMS_FILE" 2>/dev/null \
             | grep -E "^\+[[:space:]]*key='release\." | sed -E "s/.*key='([^']+)'.*/\1/")
  if [ -n "$newflags" ]; then
    warn "new remote-config flags added in this release - verify state in thermostat:"
    printf '%s\n' "$newflags" | sed 's/^/         - /'
  else
    pass "no new release.* flags added vs $PREV_TAG"
  fi
else
  warn "skipped flag diff (previous tag unavailable in repo)"
fi

# --- 3) Sage ERROR regression: NEW signatures not seen on previous release ---
echo "[3] Sage error-delta (regression vs previous release)"
sig() {
  strip_banner \
  | jq -r 'select(.level=="ERROR") | ((.logger // "") + "|" + (.message // ""))' 2>/dev/null \
  | sed -E 's/"[^"]*"/"Q"/g; s/[0-9a-fA-F-]{16,}/ID/g; s/[A-Za-z_]+\.[A-Za-z_.]+/DOTID/g; s/[0-9]+/N/g' \
  | sed '/^$/d' | sort -u
}
QBASE="group=\"$SAGE_GROUP\" system=\"$SAGE_SYSTEM\" env=\"$SAGE_ENV\""
new_sigs=$(dp sage query -q "$QBASE version=\"$RELEASE_TAG\" level=\"ERROR\"" --hours "$WINDOW_HOURS" --size 600 2>/dev/null | sig)
if [ -n "$PREV_TAG" ]; then
  old_sigs=$(dp sage query -q "$QBASE version=\"$PREV_TAG\" level=\"ERROR\"" --hours "$BASELINE_HOURS" --size 600 2>/dev/null | sig)
else
  old_sigs=""
fi
ncount=$(printf '%s\n' "$new_sigs" | grep -c . || true)
delta=$(comm -23 <(printf '%s\n' "$new_sigs") <(printf '%s\n' "$old_sigs"))
if [ -z "$delta" ]; then
  pass "0 new ERROR signatures vs ${PREV_TAG:-<none>} (new-version distinct ERROR sigs: $ncount)"
else
  bad "NEW ERROR signature(s) vs ${PREV_TAG:-<none>} (triage: benign config -> ticket, real bug -> rollback):"
  printf '%s\n' "$delta" | sed 's/^/         + /'
fi

echo
if [ "$fail" = 0 ]; then echo "SMOKE: PASS"; exit 0; else echo "SMOKE: FAIL (review above)"; exit 1; fi
