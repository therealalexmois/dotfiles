#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

model="$(jq -r '.model.display_name // "Claude"' <<< "$input")"
effort="$(jq -r '.effort.level // empty' <<< "$input")"

ctx_used="$(jq -r '.context_window.used_percentage // 0' <<< "$input" | cut -d. -f1)"
limit_5h="$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<< "$input" | cut -d. -f1)"
limit_7d="$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<< "$input" | cut -d. -f1)"

# Colors (ANSI-C quoting so \033 becomes a real ESC character)
RESET=$'\033[0m'
SEP=$'\033[38;5;255m'        # white      — main separator │
DOT=$'\033[38;5;240m'        # dim gray   — inner separator ·
C_MODEL=$'\033[38;5;75m'     # soft blue  — model
C_EFFORT=$'\033[38;5;214m'   # amber      — effort
C_CTX=$'\033[38;5;150m'      # sage green — context
C_LIMIT=$'\033[38;5;245m'    # gray       — "limits" group label
C_5H=$'\033[38;5;183m'       # lavender   — 5-hour limit
C_7D=$'\033[38;5;216m'       # peach      — 7-day limit

# Material Design Nerd Font glyphs (same set as model/effort/ctx)
ICON_5H='󰥔'                  # clock
ICON_7D='󰸗'                  # calendar

SEPARATOR="${SEP} │ ${RESET}"
INNER_SEP="${DOT} · ${RESET}"

# Main segments: each is a pre-formatted printf string (no trailing newline)
segments=()

segments+=("$(printf "${C_MODEL}󰧑 %s${RESET}" "$model")")

if [[ -n "$effort" ]]; then
  segments+=("$(printf "${C_EFFORT}󰓅 %s${RESET}" "$effort")")
fi

segments+=("$(printf "${C_CTX}󰍛 ctx %s%%${RESET}" "$ctx_used")")

# Rate limits grouped under a "limits" label; percentages are usage (used).
lim_parts=()
if [[ -n "$limit_5h" ]]; then
  lim_parts+=("$(printf "${C_5H}${ICON_5H} 5h %s%%${RESET}" "$limit_5h")")
fi
if [[ -n "$limit_7d" ]]; then
  lim_parts+=("$(printf "${C_7D}${ICON_7D} 7d %s%%${RESET}" "$limit_7d")")
fi
if [[ ${#lim_parts[@]} -gt 0 ]]; then
  inner=""
  for j in "${!lim_parts[@]}"; do
    if [[ $j -gt 0 ]]; then
      inner+="$INNER_SEP"
    fi
    inner+="${lim_parts[$j]}"
  done
  segments+=("$(printf "${C_LIMIT}usage${RESET} %s" "$inner")")
fi

# Join main segments with the white separator
result=""
for i in "${!segments[@]}"; do
  if [[ $i -gt 0 ]]; then
    result+="$SEPARATOR"
  fi
  result+="${segments[$i]}"
done

printf "%s\n" "$result"
