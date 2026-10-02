#!/bin/bash
# Открывает окно tmux в сессии Team Lead и запускает в нем команду; печатает id pane.
# Аргументы: <имя окна> <рабочий каталог> <команда> [аргументы...]
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "usage: spawn-window.sh <window-name> <workdir> <command> [args...]" >&2
  exit 2
fi

name="$1"
workdir="$2"
shift 2

# Команда исполняется в <workdir>: относительный путь к скрипту там не найдется, окно умрет с кодом 127.
case "$1" in
  /*) ;;
  */*)
    echo "command path must be absolute: $1" >&2
    exit 2
    ;;
esac

if [ -z "${TMUX_PANE:-}" ]; then
  echo "TMUX_PANE не задан: Team Lead должен работать внутри tmux" >&2
  exit 1
fi

# Сессия берется от своего pane: без -t tmux взял бы активное окно пользователя.
session="$(tmux display-message -p -t "$TMUX_PANE" '#S')"
command="$(printf '%q ' "$@")"

# Отдельное окно, а не split: pane полной ширины, наблюдатель видит строку статуса целиком.
tmux new-window -d -t "$session:" -n "$name" -c "$workdir" -P -F '#{pane_id}' "$command"
