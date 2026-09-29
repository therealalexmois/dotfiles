#!/bin/bash
# Запускает интерактивную сессию claude в worktree задачи; статус адаптера – в references/claude-cli.md.
# Аргументы: <worktree> <модель> <effort> <файл задания> [доп. аргументы claude из профиля...]
# Каталог файла задания (scratchpad) добавляется в доступ: туда пишутся отчет и описание PR.
set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "usage: claude-launch.sh <worktree> <model> <effort> <task-file> [claude args...]" >&2
  exit 2
fi

worktree="$1"
model="$2"
effort="$3"
task="$4"
shift 4

scratchpad="$(cd "$(dirname "$task")" && pwd)"
name="engineer-$(basename "$task" -task.md)"

cd "$worktree"

# Промпт идет первым: вариативный --add-dir в конце иначе съел бы его как каталог.
exec claude "$(cat "$task")" \
  --model "$model" --effort "$effort" --permission-mode acceptEdits \
  -n "$name" \
  "$@" \
  --add-dir "$scratchpad"
