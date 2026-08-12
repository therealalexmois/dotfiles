---
name: git-worktree
description: >-
  Управляет полным lifecycle локальных Git worktree и связанных task-веток:
  находит и проверяет существующие worktree, создает изолированную worktree по
  правилам репозитория, переиспользует ее без дублей, безопасно синхронизирует
  base branch и выполняет bounded post-merge cleanup. Используй для запросов
  «создай worktree», «продолжи в существующей worktree», «покажи worktree
  задачи», «обнови local main/master», «MR/PR влит, почисти за собой», «удали
  worktree и локальную ветку». Не используй для создания или merge MR/PR,
  pipeline/CI, remote branch deletion, rebase/reset либо удаления dirty
  worktree.
---

# Git Worktree

Управлять локальным lifecycle worktree одной задачи, не затрагивая другие рабочие копии и пользовательские изменения.

## Выбрать intent

| Intent | Результат |
| --- | --- |
| `inspect` | Найти точную worktree, ветку, base branch и их локальное состояние без записей |
| `create` | Создать изолированную worktree и task-ветку по правилам репозитория |
| `reuse` | Переиспользовать существующую worktree той же задачи вместо создания дубля |
| `sync` | Безопасно fast-forward локальную base branch до upstream |
| `cleanup` | После подтвержденного merge удалить task-worktree и локальную task-ветку |

Если пользователь просит несколько операций одного lifecycle, выполнить их по порядку в одном запуске. Не расширять запрос на MR/PR, CI, Jira, deployment или planning.

## Установить локальный контракт

До первой записи:

1. Найти repository root из явного пути или текущей рабочей директории. Не сканировать домашнюю директорию целиком.
2. Прочитать применимые `AGENTS.md`, `CLAUDE.md` и repository-local правила worktree, веток и setup.
3. Определить remote, base branch, task branch и worktree path из явного запроса, Git state и repository policy. Для `create` учесть контракт общей команды ниже: она использует `origin`, `origin/HEAD` и каталог `.worktrees/`. Если repository policy с ним конфликтует, остановиться и показать конфликт вместо обхода wrapper.
4. Выполнить `git status --porcelain=v1 -uall` только для рабочих копий, которые операция должна изменить.
5. Получить точное соответствие worktree и веток через `git worktree list --porcelain`.
6. Сохранить unrelated changes. Не выполнять reset, rebase, checkout с потерей данных или широкую очистку.

Явный запрос на `create`, `sync` или `cleanup` разрешает соответствующие bounded local Git writes. Не спрашивать повторное подтверждение для уже названной операции. Если target неоднозначен или безопасное действие меняется от выбора пользователя, задать один блокирующий вопрос.

## Inspect

Оставаться read-only. Вернуть только связанные с запросом:

- repository root;
- remote и base branch;
- worktree path и зарегистрированную ветку;
- clean/dirty state;
- upstream и divergence, если они доступны;
- stale registration или ambiguity.

Не читать status всех worktrees только потому, что они перечислены в Git metadata.

## Create

1. Проверить, не существуют ли уже точная task-ветка или worktree path.
2. Если существует worktree той же задачи, перейти в `reuse`.
3. Если ветка или путь заняты другой задачей, остановиться с точным конфликтом.
4. В Codex вызвать bundled [scripts/agent-worktree-create](scripts/agent-worktree-create) вместо прямого `git worktree add`:

   ```sh
   ~/.agents/skills/git-worktree/scripts/agent-worktree-create \
     --name "$task_branch" \
     --cwd "$repo_root"
   ```

   `~/.agents/skills/git-worktree` является canonical runtime-ссылкой на skill. Передать branch/name и repository root отдельными аргументами. Не собирать команду через `eval` и не передавать Claude hook JSON.
5. Не запускать wrapper после `git worktree add`: wrapper сам выполняет `git fetch origin`, создает ветку и `.worktrees/<type>-<name>`, копирует ignored файлы из `.worktreeinclude` и запускает `.worktree-setup.sh` либо `scripts/worktree-setup.sh`.
6. Если bundled script отсутствует или не executable, остановиться с blocker. Не подменять его прямым `git worktree add`.
7. Прочитать абсолютный worktree path из stdout wrapper и проверить зарегистрированный path, branch, HEAD и чистоту новой worktree.

Не создавать task-ветку в основном checkout, если repository contract требует изоляцию.

## Reuse

Переиспользовать worktree, только если ее branch и задача совпадают с запросом. Показать dirty state до продолжения и сохранить существующие изменения. Не создавать вторую worktree для той же ветки и не переносить изменения между worktrees без отдельного запроса.

## Sync

1. Выполнить fetch нужного remote с pruning, если пользователь запросил актуализацию remote state.
2. Fast-forward base branch только когда локальная branch является ancestor upstream.
3. Если base branch checked out в чистой worktree, использовать `merge --ff-only` в ней.
4. Если base branch нигде не checked out, обновить ее ref только после проверки fast-forward.
5. Если base worktree dirty или branch diverged, не применять reset/rebase. Пропустить sync и вернуть точный blocker либо gap, не затрагивая unrelated changes.

Не считать refresh task-ветки частью `sync`: merge/rebase base в task branch выполнять только по отдельному явному запросу и правилам репозитория.

## Cleanup

После явного сообщения пользователя, что MR/PR влит или задача завершена, прочитать [references/post-merge-cleanup.md](references/post-merge-cleanup.md) целиком и выполнить fast path. Не запрашивать дополнительное подтверждение merge только для повторения слов пользователя.

Не удалять remote branch без отдельного запроса. Не запускать tests, CI или project checks для локальной уборки.

## Ошибки и частичный результат

До destructive шага остановиться, если exact target не установлен, task-worktree dirty или обнаружены известные local-only commits. Если ошибка возникла после выполненного шага:

- не откатывать успешные Git-операции через reset;
- перечислить примененные и непримененные шаги;
- сохранить SHA удаляемой ветки для восстановления;
- продолжать только с оставшегося безопасного шага.

## Ответ

Вернуть кратко:

```md
Git worktree: `<intent>` <completed|partial|blocked>.
- Repository: <path>
- Worktree: <created|reused|removed|unchanged> - <path>
- Branch: <created|removed|unchanged> - <name>@<sha>
- Base sync: <updated|unchanged|skipped> - <base and upstream>
- Preserved: <unrelated state or none>
- Gaps: <none or exact blocker>
```

Не пересказывать все найденные worktrees. После cleanup указать команду восстановления локальной ветки из сохраненного SHA, если использовалось force-delete.

## Done means

- выбран один точный repository и task target;
- repository-local policy соблюдена;
- unrelated worktrees и изменения сохранены;
- write выполнен только для выбранного intent;
- финальное Git-состояние перечитано;
- destructive cleanup имеет сохраненный recovery SHA;
- внешние системы и remote branches не изменены без отдельного запроса.
