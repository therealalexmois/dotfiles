#!/usr/bin/env bash
# Claude Code status line script
# Receives JSON via stdin

input=$(cat)

# Model
model=$(echo "$input" | jq -r '.model.display_name // empty')

# Current directory (basename) and git branch
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
folder=$(basename "$cwd")
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  location="$folder ($branch)"
else
  location="$folder"
fi

# Context window
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
ctx_remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
if [ -n "$ctx_size" ] && [ -n "$ctx_remaining" ]; then
  ctx_size_k=$(( ctx_size / 1000 ))
  ctx_part="ctx ${ctx_size_k}k | $(printf '%.0f' "$ctx_remaining")% left"
elif [ -n "$ctx_size" ]; then
  ctx_size_k=$(( ctx_size / 1000 ))
  ctx_part="ctx ${ctx_size_k}k"
else
  ctx_part=""
fi

# Rate limits: 5-hour (closest to "4-hour") and 7-day weekly
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rate_part=""
if [ -n "$five_pct" ]; then
  rate_part="5h: $(printf '%.0f' "$five_pct")% used"
fi
if [ -n "$week_pct" ]; then
  if [ -n "$rate_part" ]; then
    rate_part="$rate_part | 7d: $(printf '%.0f' "$week_pct")% used"
  else
    rate_part="7d: $(printf '%.0f' "$week_pct")% used"
  fi
fi

# Assemble parts
parts=()
[ -n "$model" ]    && parts+=("$model")
[ -n "$location" ] && parts+=("$location")
[ -n "$ctx_part" ] && parts+=("$ctx_part")
[ -n "$rate_part" ] && parts+=("$rate_part")

# Join with separator
out=""
for part in "${parts[@]}"; do
  if [ -z "$out" ]; then
    out="$part"
  else
    out="$out  |  $part"
  fi
done

echo "$out"
