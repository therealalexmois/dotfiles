---
name: gitlab-mcp-workflow
description: >-
  Как работать с GitLab через dpGitlab MCP (Spirit CLI) и git push options в проекте dwsai-data-agent (tenant dwsai):
  создать merge request, обновить его заголовок и описание, посмотреть MR, pipeline, job и CI-логи.
  Главное: dpGitlab MCP не умеет создавать MR и issues (только чтение и правка существующего MR).
  MR создается инструментом create_merge_request сервера dpMR за один вызов; git push -o merge_request.create остается как fallback.
  Используй этот skill, когда пользователь хочет: «создай MR», «открой merge request», «запушь и сделай MR»,
  «обнови описание или заголовок MR», «посмотри MR / pipeline / job», «почему CI красный», «статус пайплайна»,
  «GitLab MCP не создает MR, как тогда», «правила имен веток в репо». Срабатывает, даже если слово «MCP» не названо,
  но речь про создание или инспекцию MR и CI в этом GitLab.
  Оформление текста MR по шаблону репозитория делает отдельный skill gitlab-mr-author;
  этот skill про механику создания и инспекции через MCP и push options.
---

# GitLab через dpGitlab MCP и push options

Создание и инспекция merge request и CI в GitLab (`gitlab.tcsbank.ru`, tenant `dwsai`, repository `dwsai-data-agent`) из агентских инструментов.

## Что dpGitlab MCP умеет и чего не умеет

Умеет только чтение и правку существующего:

| Инструмент | Назначение |
|------------|------------|
| `dp_gitlab_repos` | Список репозиториев тенанта |
| `dp_gitlab_merge-requests` | Список MR (`state`, `limit`) |
| `dp_gitlab_merge-request` | Один MR с diff и комментариями (`id`) |
| `dp_gitlab_update-merge-request` | Изменить `title` и/или `description` у MR по `id` |
| `dp_gitlab_pipelines` | Список pipeline репозитория |
| `dp_gitlab_pipeline` | Один pipeline |
| `dp_gitlab_job` | Job pipeline: статус и логи |

Не умеет: создать MR, создать issue, merge, approve, оставить комментарий. Для создания MR есть отдельный сервер dpMR, см. ниже.

У почти всех инструментов обязательны `tenant` (здесь `dwsai`) и `repository` (`dwsai-data-agent`).

## Создать MR

Основной способ - инструмент `create_merge_request` сервера dpMR. Он создает MR за один вызов: ставит source-ветку, target, title и description, опционально draft, labels, squash и удаление ветки после merge. Отдельный `dp_gitlab_update-merge-request` для первичного создания не нужен.

Обязательные параметры:

| Параметр | Назначение |
|----------|------------|
| `path` | Полный путь рабочей копии репозитория |
| `branch` | Source-ветка MR |
| `title` | Заголовок MR |
| `description` | Описание MR (многострочное передается чисто) |
| `empty_commit_message` | Сообщение пустого коммита, см. ниже |

Опционально: `target` (по умолчанию `main`), `draft`, `labels` (через запятую), `squash`, `delete_src`.

Две обязательные оговорки:

- `empty_commit_message`: dpMR создает MR тем же механизмом git push с push options и для гарантии передачи опций сначала делает пустой коммит с этим сообщением. То есть в ветку добавляется пустой коммит. Если это нежелательно, используй fallback ниже.
- `target` по умолчанию `main`, а этот репозиторий на `master`. Всегда передавай `target=master`.

Пример:

```text
create_merge_request \
  path=<полный путь к репо> \
  branch=fix/my-bug \
  target=master \
  title="fix(scope): ..." \
  description="...многострочное описание..." \
  empty_commit_message="ci: open merge request"
```

Push rule на имя ветки действует и здесь (механизм - тот же push), см. «Имена веток».

### Fallback: создать MR через git push

Если пустой коммит нежелателен или dpMR недоступен, MR создается напрямую push options GitLab:

```text
git push -u origin <local-branch>:<remote-branch> \
  -o merge_request.create \
  -o merge_request.target=master \
  -o merge_request.remove_source_branch
```

GitLab напечатает ссылку на созданный MR. Заголовок и описание ставь отдельно через MCP:

```text
dp_gitlab_update-merge-request --tenant dwsai --repository dwsai-data-agent --id <NN> --title "..." --description "..."
```

### Имена веток

Имя remote-ветки должно проходить push rule репозитория:

```text
^(?:master|(?:feat|fix|hotfix|refactor|chore|perf|test|ci|revert|docs)/[a-z0-9]+(?:-[a-z0-9]+)*)$
```

Подходят `fix/my-bug`, `docs/jira-workflow`, `chore/type-check-no-cache`. Иначе push отклоняется.

### Грабля: bare git push в worktree

Если локальная ветка названа не по правилу (например, harness-worktree дает `worktree-fix+...`), bare `git push` ругается и не пушит. Пушь явным refspec в policy-совместимое имя:

```text
git push origin HEAD:fix/my-bug
```

То же имя используй в `merge_request.create` при первом пуше.

## Посмотреть MR, pipeline и CI-логи

- `dp_gitlab_merge-requests` с `tenant`, `repository`, при необходимости `state` (`opened`, `merged`, `closed`, `all`) и `limit`.
- `dp_gitlab_merge-request` с `id`: детали, diff, комментарии.
- `dp_gitlab_pipelines`, `dp_gitlab_pipeline`, `dp_gitlab_job`: статусы пайплайнов и логи job, чтобы понять, почему CI красный.

Точные флаги инструмента смотри в его схеме перед вызовом, не выдумывай.

## Safety

- Пуш и создание MR это outward-facing действия. Создавай MR только после явного подтверждения; покажи ветку, target и заголовок.
- `dp_gitlab_update-merge-request` перезаписывает `title` и `description` целиком. Перед точечной правкой прочитай текущее через `dp_gitlab_merge-request`.
- Коммить и пушь только то, что в scope; не подмешивай чужие изменения.

## Связь с другими skill

- `gitlab-mr-author` сочиняет заголовок и описание MR по шаблону репозитория `.gitlab/merge_request_templates/default.md`. Этот skill про механику create и inspect. Текст бери из `gitlab-mr-author`, создание и обновление делай отсюда.
