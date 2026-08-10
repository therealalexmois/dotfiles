# Post-merge cleanup

Выполнять локальную уборку завершенной task-ветки быстро и без исследования несвязанных worktrees.

## Preconditions

Начинать mutation только если пользователь явно сообщил о merge или завершении задачи и exact task-worktree с branch определены.

До cleanup зафиксировать:

- repository root;
- remote и base branch;
- task-worktree path;
- task branch;
- task branch HEAD как recovery SHA;
- clean state task-worktree;
- upstream divergence, если upstream ref еще доступен;
- исходный status base worktree, если она будет синхронизирована.

Dirty task-worktree или известные local-only commits блокируют удаление. Dirty или diverged base worktree блокирует только base sync: не изменять ее, но продолжить cleanup безопасной task-worktree и явно назвать пропущенный sync.

## Fast path

Нормальный cleanup должен укладываться в два tool rounds.

### Round 1: local preflight

Одним read-only вызовом:

1. Прочитать `git worktree list --porcelain` и выбрать только task-worktree и worktree base branch.
2. Проверить branch и `git status --porcelain=v1 -uall` task-worktree.
3. Сохранить task branch HEAD.
4. Проверить upstream divergence, если upstream существует.
5. Проверить, можно ли fast-forward base branch без reset или rebase.

Не читать status других worktrees. Не обращаться к GitLab/GitHub только для повторной проверки явного сообщения пользователя о merge.

### Round 2: mutation и verification

Одним последовательным terminal-вызовом:

1. Выполнить полный `git fetch --prune <remote>`, а не fetch одной base branch.
2. Синхронизировать base branch только безопасным fast-forward:
   - если она checked out в чистой worktree, выполнить `git merge --ff-only <remote>/<base>`;
   - если она нигде не checked out и local ref является ancestor upstream, обновить local ref до upstream;
   - если worktree dirty или branch diverged, пропустить sync без изменения ее состояния.
3. Удалить exact task-worktree через `git worktree remove <exact-path>` без `--force`.
4. Удалить exact local task branch через `git branch -d <branch>`.
5. Если `-d` отклоняет squash-merged branch из-за ancestry, использовать `git branch -D <branch>` только когда:
   - пользователь явно подтвердил merge;
   - удалена именно выбранная clean task-worktree;
   - branch HEAD совпадает с сохраненным recovery SHA;
   - в доступном session/Git evidence нет local-only commits.
6. Выполнить `git worktree prune` только если target directory уже отсутствовал или Git оставил stale registration.
7. В том же вызове проверить:
   - target path и registration отсутствуют;
   - local task branch отсутствует;
   - base branch совпадает с upstream, если sync не был пропущен;
   - status base worktree не получил изменений от cleanup.

Дополнительный tool round допустим только после фактической ошибки. Диагностировать только упавший шаг.

## Boundaries

- Отсутствие remote source branch после fetch/prune считать нормальным no-op.
- Не выполнять `git push <remote> --delete` без отдельного запроса.
- Не удалять другие stale registrations заодно.
- Не выполнять tests, linters, CI или project checks.
- Не запускать повторный широкий audit после успешной финальной проверки.

## Recovery

После удаления сохранить в ответе `<branch>@<recovery_sha>`. Если использовался `git branch -D`, дать команду:

```bash
git branch <branch> <recovery_sha>
```

Не обещать бессрочное хранение reflog; recovery SHA должен быть записан явно.
