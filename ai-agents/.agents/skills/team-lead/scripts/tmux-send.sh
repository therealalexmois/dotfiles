#!/bin/bash
# Отправляет текст из файла в интерактивную сессию инженера в tmux и ждет начала работы.
# Аргументы: <pane_id> <файл с текстом> [codex|claude]
# Признак работы берется из pane-watch.py: регулярки живут только там.
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: tmux-send.sh <pane> <file> [codex|claude]" >&2
  exit 2
fi

pane="$1"
file="$2"
kind="${3:-codex}"
watch="$(cd "$(dirname "$0")" && pwd)/pane-watch.py"

case "$kind" in
  codex | claude) ;;
  *)
    echo "unknown kind: $kind" >&2
    exit 2
    ;;
esac

# В режиме Vim текст, вставленный в Normal, съедается как команды: сначала в Insert.
if tmux capture-pane -p -t "$pane" | tail -5 | grep -q 'Vim: Normal'; then
  tmux send-keys -t "$pane" i
  sleep 0.5
fi

tmux send-keys -t "$pane" -l "$(cat "$file")"
sleep 1

# Длинный текст приходит вставкой: первый Enter часто только закрывает ее.
for _ in 1 2 3 4 5 6; do
  tmux send-keys -t "$pane" Enter
  sleep 2

  if python3 "$watch" --is-busy "$pane" --kind "$kind"; then
    echo "отправлено, $kind работает"
    exit 0
  fi
done

echo "$kind не начал работу после отправки, проверь pane $pane" >&2
exit 1
