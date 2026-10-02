#!/bin/bash
# Запускает интерактивную сессию Codex в worktree задачи.
# Аргументы: <worktree> <модель> <effort> <файл задания> [доп. аргументы codex из профиля...]
# Каталог файла задания (scratchpad) добавляется в песочницу: туда пишутся отчет и описание PR.
set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "usage: codex-launch.sh <worktree> <model> <effort> <task-file> [codex args...]" >&2
  exit 2
fi

worktree="$1"
model="$2"
effort="$3"
task="$4"
shift 4

scratchpad="$(cd "$(dirname "$task")" && pwd)"

exec codex -C "$worktree" -m "$model" -c model_reasoning_effort="$effort" \
  -s workspace-write -a on-request \
  --add-dir "$scratchpad" \
  "$@" \
  "$(cat "$task")"
