---
name: work-release-manager
description: >-
  Production release manager for dwsai-data-agent: changelog, release plan gate, release tag, GitLab tag pipeline, Spirit Deploy, monitoring, smoke checks, thermostat flags, wiki release manifest, TiMe announcement, rollback guardrails and hotfix roll-forward. Use only for explicit $work-release-manager or «сделай релиз», «выкати в прод», «продолжи релиз», «hotfix», production release. Changing actions require confirmation.
disable-model-invocation: true
---

# Release Manager (dwsai-data-agent)

Проводит production-релиз проекта dwsai-data-agent от changelog до анонса. Skill - advisory-оркестратор: он сам не дублирует механику деплоя или GitLab, а выстраивает порядок шагов, готовит точные команды и тексты, и на каждом необратимом шаге спрашивает подтверждение.

## Место в цепочке skills

- **spirit-deploy** - механика `dp deploy` (этот skill вызывает ее на шаге deploy и rollback).
- **gitlab-mcp-workflow** - инспекция pipeline/job через dpGitlab.
- **jira-team-workflow** - перевод задач релиза по статусам.
- **writing-russian-editor** - полировка текста changelog и анонсов.

Не дублируй эти skills, ссылайся на них.

Для параллельного read-сбора есть собственные subagents в [subagents/](subagents): `release-diff-agent` (changelog/ownership) и `observability-agent` (Sage-регрессия). Это prompt-спеки, запускаются через Agent tool, возвращают факты; оркестрацию, статус и коммуникацию держит main.

## Правило безопасности (advisory)

Все необратимое выполняется только после явного подтверждения через `AskUserQuestion`:

- `git push <tag>`;
- `dp deploy do` (production deploy);
- `dp deploy rollback`;
- создание/правка wiki Release manifest;
- публикация сообщения в Time.

Read-only шаги (git log/diff, `dp deploy get/watch`, `dp kube get`, `dp sage query`, инспекция pipeline) выполняются без подтверждения. Production - повышенная осторожность: всегда показывай команду целиком и dry-run перед изменяющим действием.

## Предусловия

- Ветка `master`, рабочее дерево чистое.
- `git fetch --tags`; `master` обновлен из `origin` (`git merge --ff-only origin/master`).
- Доступны: `dp` CLI (плагины deploy, kube, sage, gitlab), `jq`, `git`; MCP dpGitlab, dpSage, dpKube, time.
- Если чего-то нет - остановись и попроси подключить, не выдумывай.
- Предполетную проверку автоматизирует `scripts/preflight_release.sh` (шаг 0).

## Workflow

### 0. Preflight

Перед стартом - предполетная проверка (read-only, JSON):

```bash
scripts/preflight_release.sh
```

Проверяет: репозиторий dwsai-data-agent, чистоту дерева, ветку `master`, наличие `git`/`dp`/`jq`, детект previous release tag (только валидный формат `release-NNNNNN.NNNN`) и candidate tag. `status=blocked` - стоп, разбери `errors`. Грязное дерево - `warning`, продолжать только с явного approve.

### 1. Предыдущий production-релиз

```bash
git tag -l 'release-*' --sort=-version:refname | head
```

Production-теги: `release-YYMMDD.HHMM`. Test/dev: `dev-YYMMDD.HHMM`. Предыдущий prod-релиз - верхний `release-*` по version-сортировке.

### 2. Changelog

Собери changelog от предыдущего prod-релиза до `HEAD`. Опирайся не только на commit messages (они бывают плохими), а на:

```bash
git log --oneline <prev-release>..HEAD
git diff --stat <prev-release>..HEAD
git log --format='%h %s%n%b' <prev-release>..HEAD   # тикеты DWSAI-XXX из тел коммитов
```

Детерминированную факт-базу (commits, diffstat, тикеты, candidate tag) дает `scripts/collect_release_diff.sh` (JSON). Для тяжелого сбора (GitLab compare + MR + Jira + owner-маппинг) можно запустить subagent `release-diff-agent` ([subagents/release-diff-agent.md](subagents/release-diff-agent.md)) через Agent tool - он возвращает структурный changelog/ownership, решения остаются у main.

Сгруппируй по типам (Features / Fixes / Docs / Chore), описывай реальные изменения по изменённым файлам, добавь блок «Риски и наблюдения». Покажи draft, при необходимости прогони через `writing-russian-editor`, подтверди.

`CHANGELOG.md` в проекте нет и не заводим: changelog живет в сообщении annotated-тега (`git tag -n99 <tag>`, `git show <tag>`).

### 3. Feature flags (обязательный шаг)

Релиз может добавить новые remote-config флаги (`release.*`). Если флаг есть в коде, но не выставлен в thermostat, в prod пойдет ERROR `FLAG_NOT_FOUND` и фича резолвится в default.

Детект release impact в диапазоне (read-only, JSON) - три скрипта:

```bash
scripts/detect_feature_flags.sh <prev> <cur>           # новые release.* флаги
scripts/detect_db_migrations.sh <prev> <cur>           # миграции в migrations/
scripts/detect_secrets_runtime_config.sh <prev> <cur>  # env в deploy/service.yml (только имена)
```

Эти сигналы идут в план релиза (шаг 4), секцию Operational impact тега (шаг 5) и в human-gates деплоя (шаг 7). Эквивалент детекта флагов вручную:

```bash
git diff <prev-release>..HEAD -- src/app/infrastructure/remote_config/params.py \
  | grep -E "^\+\s*key='release\." | sed -E "s/.*key='([^']+)'.*/\1/"
```

Для каждого нового флага инженер должен проверить в thermostat, **включен он или выключен**, и что это соответствует замыслу релиза. У `dp` нет плагина thermostat: проверка идет через web-UI thermostat. Runtime-сигнал незарегистрированного флага - Sage `FLAG_NOT_FOUND` (шаги 8-9: мониторинг и smoke).

Затем - **явный gate через `AskUserQuestion`**: «Подтверди, что новые FF проверены в thermostat и выставлены как задумано (вкл/выкл)». Не двигайся к анонсу, пока инженер не подтвердил. Состояние флагов влияет на аудиторию анонса (шаг 13).

### 4. План релиза (гейт перед тегом)

Собери план из фактов шагов 0-3 и покажи на approve ДО создания тега. Формат - [templates/release-plan-template.md](templates/release-plan-template.md). План живет в чате (в Time/wiki не публикуется), его итоги позже попадают в manifest и анонсы.

Состав: scope (prev → candidate, commits, тикеты, краткий changelog), Operational impact из детекторов (шаг 3), риски, rollback target, какие анонсы будут, список предстоящих необратимых шагов.

Approve через **`AskUserQuestion`**. Без approve тег не создавай; если после approve HEAD сдвинулся - перегенерируй план.

### 5. Annotated release-тег

Имя: `release-YYMMDD.HHMM` (текущее время выпуска). CI валидирует формат регуляркой `^(release|dev)-\d{6}\.\d{4}$` - 6-значная дата, 4-значное время. Сообщение тега (annotated, не lightweight) включает changelog и секцию Operational impact:

```text
Release: <release-tag>
Previous release: <previous-release-tag>

Changelog
- Features / Fixes / Docs / Chore

Operational impact
- DB migrations: <none|present>
- Secrets/runtime config: <none|changed>
- Feature flags: <none|changed>
- API breaking changes: <none|present|unknown>
```

```bash
git tag -a release-YYMMDD.HHMM -F <changelog-file> <commit>
git cat-file -t release-YYMMDD.HHMM   # ожидаем: tag
```

Перед `git push origin <tag>` - **`AskUserQuestion`**.

### 6. GitLab tag-pipeline

После push найди pipeline через dpGitlab (branch == имя тега), дождись терминального статуса. На теге выполняются только build-job'ы (`build-test`, `build` - сборка образа `dwsai/dwsai-data-agent:<tag>`); тесты/линт/type-check привязаны к MR и default-branch, на тег не запускаются. Red → стоп, покажи логи упавшего job, предложи шаг. Удобно поллить в фоне:

```bash
dp gitlab pipeline -t dwsai -r dwsai-data-agent -i <pipeline-id>
```

### 7. Deploy через spirit-deploy

Прочитай skill **spirit-deploy** и кратко перескажи flow. Особенности установленного плагина (v0.0.14), отличные от общей документации:

- Подкоманды: `do`, `get`, `watch`, `rollback`. **Нет** `status` (используй `get`/`watch`). **Нет** флага `--env` (среда задана конфигом приложения). У `do` есть `--dry-run`.
- `do` **требует локальный `application.yaml`** (чистого API-режима «только образ» нет).

Day-2 image-bump (конфиг не меняется):

```bash
dp deploy get --tenant dwsai --app data-agent-prod          # пишет application.yaml (текущий prod-конфиг)
# подменить tag и sha на новый release (sed, без вывода значений env):
sed -i '' -e 's/<old-tag>/<new-tag>/' -e 's/<old-sha>/<new-sha>/' application.yaml
dp deploy do --dry-run --local --tenant dwsai --app data-agent-prod --component data-agent-webservice-prod
# dry-run должен показать только смену образа (tag+sha). Затем AskUserQuestion:
dp deploy do --local --tenant dwsai --app data-agent-prod --component data-agent-webservice-prod
dp deploy watch --tenant dwsai --app data-agent-prod        # ждет Running/Failed
rm -f application.yaml                                       # содержит значения env, не в .gitignore - удалить
```

Случай новых env (в `deploy/service.yml` добавились переменные): image-only недостаточно. Добавь переменную в `application.yaml` со значением и **`isModified: true`** (без него сервер игнорирует значение), деплой полным конфигом (`--local`), список env в `application.yaml` держи в соответствии со `service.yml`.

Если детекторы (шаг 3) дали DB migrations `present` или Secrets/runtime config `changed` - перед деплоем явный **`AskUserQuestion`** с перечислением, что меняется (имена env без значений). Это в дополнение к общему gate.

Перед `dp deploy do` (production) - **`AskUserQuestion`**.

### 8. Мониторинг (dpKube + dpSage)

Поды, образ, готовность, рестарты по **обоим** кластерам:

```bash
dp kube get clusters                                        # валидные имена кластеров (с суффиксом .prod)
dp kube get logs -n dwsai-data-agent-prod-prod-daas -e prod \
  -c bm-ix-m5-inside-wl1.prod,bm-ix-m5-inside-wl4.prod -l 1
```

Ожидаем: все контейнеры на новом теге, `ready=true`, `restarts=0`, `status=Running`. `kubectl exec` в prod-namespace запрещен RBAC - готовность подов и есть подтверждение, что probe `/system/startup|readiness|liveness` зелены.

Логи в Sage - **регрессионно**, а не голым ERROR-count. В логах есть поле `version="release-..."`, фильтруй по нему:

```bash
dp sage query -q 'group="dwsai" system="data-agent" env="prod" version="<new-tag>" level="ERROR"' --hours 1
dp sage query -q 'group="dwsai" system="data-agent" env="prod" version="<prev-tag>" level="ERROR"' --hours 24
```

Сравни сигнатуры: фейли только на ERROR, которых не было на прошлом релизе. Фон (ошибки трафика, давние FLAG_NOT_FOUND) не должен валить вывод. Наблюдай короткое окно после деплоя.

Тяжелый сбор и группировку логов с подготовкой кликабельных deep-ссылок можно делегировать subagent `observability-agent` ([subagents/observability-agent.md](subagents/observability-agent.md)) через Agent tool - он возвращает регрессию, severity и ссылки; решение о rollback остается у main.

### 9. Post-release smoke

```bash
RELEASE_TAG=release-YYMMDD.HHMM scripts/release_smoke.sh
```

Скрипт (read-only, на `dp kube`/`dp sage`) проверяет: образ всех подов == release-тег, все ready, restarts в пределах порога (оба кластера); новые `release.*` флаги в диффе (предупреждение - проверить в thermostat); Sage error-delta (новые ERROR-сигнатуры против прошлого релиза). FAIL на error-delta = нужна ручная триажа: безобидное (как FLAG_NOT_FOUND → тикет) или реальная регрессия (→ rollback).

### 10. Проверка задач в JIRA (Done)

После верификации релиза на проде сверь, что все задачи, вошедшие в релиз, в статусе `Done`.

- Собери тикеты релиза: `git log --format='%s%n%b' <prev>..<cur> | grep -oiE '(DWSAI|DGP|DC)-[0-9]+' | sort -u`; при необходимости добавь тикеты из веток и описаний MR (`dp_gitlab_merge-requests`).
- Для каждого тикета проверь статус через `dp_jira_issue` (skill `jira-team-workflow`).
- Не-`Done` задачи переводи в `Done` (поток `RELEASE PREPARATION → DONE`) только после подтверждения через `AskUserQuestion`.
- MR без связанного тикета отметь как наблюдение (изменение без задачи), тикет не выдумывай.

Анонсы релиза - четыре артефакта: wiki Release manifest (полная запись), Time post (инженерам), thread к нему (операционные детали), user announcement (пользователям). Общие правила (status taxonomy, распределение информации, язык, ссылки, неизвестные данные, секреты) - [references/announcement-rules.md](references/announcement-rules.md). Manifest идет первым: Time post на него ссылается.

### 11. Release manifest (wiki)

Полная техническая запись релиза. Собери из данных шагов 1-10 и создай/обнови через dpWiki дочернюю страницу к `04 – Release Manifest` (id `8451788585`, space DW). Заголовок: `YYYY-MM-DD - data-agent - <release-tag>` (дефисы). Формат - [templates/release-manifest-template.md](templates/release-manifest-template.md): 8 секций (Summary, Links, Ops, Changelog, Ownership, Known issues, Post-release observation, Follow-ups). Сохрани URL созданной страницы - он нужен Time post (шаг 12).

Создание/правка manifest - изменяющее действие (публикация на корпоративный wiki): покажи draft и **`AskUserQuestion`** перед записью. Секреты в manifest не рендери.

### 12. Time post (инженеры, канал dws-ai-agent)

Короткий технический анонс, без таблиц, со ссылкой на manifest. Формат - [templates/time-post-template.md](templates/time-post-template.md).

- Compact links одной строкой: Pipeline, Compare, Deploy, Logs, **Manifest** (URL из шага 11).
- `Status` (одно значение из taxonomy), `User impact` и `Rollback target` - отдельными строками.
- Changelog с owner-ами в буллетах (`@login`). Длинные Sage deep-ссылки и post-release observation - в тред ([templates/thread-template.md](templates/thread-template.md)), не в тело.
- Лимит Time 4000 символов. Перед постом в канал - DM-self-test (`dm` на свой username), проверь Mattermost-markdown. Публикация - только после **`AskUserQuestion`**.

Канал `dws-ai-agent`: https://time.tbank.ru/tinkoff/channels/dws-ai-agent.

### 13. User announcement (канал ~dwsai-announcement)

Только при наличии user impact. Формат - [templates/user-announcement-template.md](templates/user-announcement-template.md): «Что изменилось / Что это даёт / Нужно ли что-то сделать / Ограничения». Язык - русский, приложение - **Nessy Data Agent** (не `data-agent` / `data-agent-prod`).

Правило аудитории по feature flags (шаг 3): изменение за выключенным в prod флагом в user announcement НЕ включай - оно идет только инженерам. Если включенных user-facing изменений нет, не выдумывай: выведи строку `User-facing announcement is not required: no user impact` (в чат, в канал не постим) или согласуй пропуск. Публикация в канал `~dwsai-announcement` (public, id `dspn99zritbs7duks3g4skjc6r`) - после **`AskUserQuestion`**.

### 14. Rollback guardrail

При провале деплоя или критической регрессии - не откатывай молча. Подготовь план, покажи команду, спроси через **`AskUserQuestion`**, и только потом:

```bash
dp deploy rollback --tenant dwsai --app data-agent-prod
```

Лог-шум (как FLAG_NOT_FOUND с fallback на default) при здоровом сервисе - не повод для rollback, а кандидат на отдельный тикет.

## Hotfix (roll-forward с master)

Срочный фикс критической проблемы в prod. Сначала гейт rollback-vs-roll-forward (шаг 14): если безопасный фикс не готов быстро - сперва rollback на предыдущий релиз, hotfix следом без спешки.

Roll-forward - тот же workflow с сокращенной церемонией; технические шаги и гейты не урезаются:

- Фикс едет в `master` через MR (критические тесты обязательны). Отдельного формата тега нет: CI-регулярка допускает только `release-*`/`dev-*`, hotfix-тег - обычный `release-YYMMDD.HHMM`.
- Обязательные шаги: 0-3 (preflight, previous release, сокращенный changelog, impact-детекторы) → 4 (короткий план) → 5-9 (тег, pipeline, deploy, мониторинг, smoke).
- «Попутчики»: при trunk-based вместе с фиксом уедут все незарелиженные коммиты `master`. Покажи их явно в плане (`scripts/collect_release_diff.sh`) и подтверди через **`AskUserQuestion`**. Попутчики неприемлемы - это не roll-forward кейс: остановись и согласуй ручной cherry-pick от тега (вне default-процедуры).
- Сообщение тега начинай с `Hotfix for <broken-release>: <причина>`, дальше обычный формат.
- Коммуникация сокращенная, но не нулевая: manifest обязателен (компактный), Time post короткий (Status, причина hotfix, ссылка на manifest), thread со ссылками Sage по инциденту, user announcement только при user impact.
- Сломанный релиз: обнови Known issues / Status в его manifest и при необходимости в его Time-треде.

## Итоговый отчет

В конце релиза верни: release-тег, **release status** (одно значение из taxonomy), changelog, статус pipeline, статус deploy (ревизия), результат мониторинга, результат smoke, проверенные FF, статусы задач JIRA (все ли Done), URL wiki manifest, ссылки на Time post и user announcement, оставшиеся ручные действия.

## Константы проекта

- tenant: `dwsai`; репозиторий: `dwsai-data-agent`
- Spirit Deploy app: `data-agent-prod`; компонент: `data-agent-webservice-prod`; serviceId: `a5392cc8-c3fd-4512-82d4-5394623f6be5`
- namespace: `dwsai-data-agent-prod-prod-daas`; кластеры: `bm-ix-m5-inside-wl1.prod`, `bm-ix-m5-inside-wl4.prod`
- imageStream: `docker-hosted.artifactory.tcsbank.ru/dwsai/dwsai-data-agent`
- Sage: group `dwsai`, system `data-agent`, env `prod`
- CI tag-регулярка: `^(release|dev)-\d{6}\.\d{4}$`
- Time-каналы: инженерам `dws-ai-agent` (https://time.tbank.ru/tinkoff/channels/dws-ai-agent); пользователям `~dwsai-announcement` (id `dspn99zritbs7duks3g4skjc6r`, public)
- User-facing имя приложения для анонсов: `Nessy Data Agent` (внутренние имена `data-agent` / `data-agent-prod` в user-анонс не выносить)
- Wiki Release manifest parent: `04 – Release Manifest` (id `8451788585`, space DW); на релиз - дочерняя страница, заголовок `YYYY-MM-DD - data-agent - <release-tag>`
