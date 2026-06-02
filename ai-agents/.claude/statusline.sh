#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

model="$(jq -r '.model.display_name // "Claude"' <<< "$input")"
effort="$(jq -r '.effort.level // empty' <<< "$input")"
session_name="$(jq -r '.session_name // empty' <<< "$input")"
cost_total="$(jq -r '.cost.total // empty' <<< "$input")"

raw_dir="$(jq -r '.workspace.project_dir // .cwd // empty' <<< "$input")"
project_dir="${raw_dir/#$HOME/~}"

git_branch=""
if [[ -n "$raw_dir" ]]; then
  git_branch="$(git -C "$raw_dir" branch --show-current 2>/dev/null || true)"
fi

ctx_used="$(jq -r '.context_window.used_percentage // 0' <<< "$input" | cut -d. -f1)"
limit_5h="$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<< "$input" | cut -d. -f1)"
limit_7d="$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<< "$input" | cut -d. -f1)"
reset_5h="$(jq -r '.rate_limits.five_hour.resets_at // empty' <<< "$input")"
reset_7d="$(jq -r '.rate_limits.seven_day.resets_at // empty' <<< "$input")"

# Format seconds-until-reset as "Xh Ym" or "Ym" when under one hour.
_fmt_reset() {
  local epoch="$1"
  local now secs h m
  now="$(date +%s)"
  secs=$(( epoch - now ))
  [[ $secs -le 0 ]] && return
  h=$(( secs / 3600 ))
  m=$(( (secs % 3600) / 60 ))
  if [[ $h -gt 0 ]]; then
    printf "%dh %dm" "$h" "$m"
  else
    printf "%dm" "$m"
  fi
}

reset_5h_str=""
[[ -n "$reset_5h" ]] && reset_5h_str="$(_fmt_reset "$reset_5h")"
reset_7d_str=""
[[ -n "$reset_7d" ]] && reset_7d_str="$(_fmt_reset "$reset_7d")"

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
C_DIR=$'\033[38;5;222m'      # warm yellow — project dir
C_BRANCH=$'\033[38;5;114m'   # muted green — git branch
C_SESSION=$'\033[38;5;189m'  # pale purple — session name
C_COST=$'\033[38;5;208m'     # orange      — cost

# Material Design Nerd Font glyphs (same set as model/effort/ctx)
ICON_5H='󰥔'                  # clock
ICON_7D='󰸗'                  # calendar

SEPARATOR="${SEP} │ ${RESET}"
INNER_SEP="${DOT} · ${RESET}"

# Main segments: each is a pre-formatted printf string (no trailing newline)
segments=()

if [[ -n "$session_name" ]]; then
  [[ ${#session_name} -gt 25 ]] && session_name="${session_name:0:24}…"
  segments+=("$(printf "${C_SESSION}󰓆 %s${RESET}" "$session_name")")
fi

if [[ -n "$project_dir" ]]; then
  if [[ -n "$git_branch" ]]; then
    segments+=("$(printf "${C_DIR}󰉋 %s${RESET}${DOT} ${C_BRANCH} %s${RESET}" "$project_dir" "$git_branch")")
  else
    segments+=("$(printf "${C_DIR}󰉋 %s${RESET}" "$project_dir")")
  fi
fi

segments+=("$(printf "${C_MODEL}󰧑 %s${RESET}" "$model")")

if [[ -n "$effort" ]]; then
  segments+=("$(printf "${C_EFFORT}󰓅 %s${RESET}" "$effort")")
fi

segments+=("$(printf "${C_CTX}󰍛 ctx %s%%${RESET}" "$ctx_used")")

if [[ -n "$cost_total" ]]; then
  segments+=("$(printf "${C_COST}󰀫 \$%.4f${RESET}" "$cost_total")")
fi

# Rate limits grouped under a "limits" label; percentages are usage (used).
lim_parts=()
if [[ -n "$limit_5h" ]]; then
  if [[ -n "$reset_5h_str" ]]; then
    lim_parts+=("$(printf "${C_5H}${ICON_5H} 5h %s%% resets in %s${RESET}" "$limit_5h" "$reset_5h_str")")
  else
    lim_parts+=("$(printf "${C_5H}${ICON_5H} 5h %s%%${RESET}" "$limit_5h")")
  fi
fi
if [[ -n "$limit_7d" ]]; then
  if [[ -n "$reset_7d_str" ]]; then
    lim_parts+=("$(printf "${C_7D}${ICON_7D} 7d %s%% resets in %s${RESET}" "$limit_7d" "$reset_7d_str")")
  else
    lim_parts+=("$(printf "${C_7D}${ICON_7D} 7d %s%%${RESET}" "$limit_7d")")
  fi
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
