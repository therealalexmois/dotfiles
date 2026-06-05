---
name: work-release-manager
description: >-
  Production release manager for dwsai-data-agent: changelog, release tag, GitLab tag pipeline, Spirit Deploy, monitoring, smoke checks, thermostat flags, TiMe announcement and rollback guardrails. Use only for explicit $work-release-manager or «сделай релиз», «выкати в прод», «продолжи релиз», production release. Changing actions require confirmation.
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

## Правило безопасности (advisory)

Все необратимое выполняется только после явного подтверждения через `AskUserQuestion`:

- `git push <tag>`;
- `dp deploy do` (production deploy);
- `dp deploy rollback`;
- публикация сообщения в Time.

Read-only шаги (git log/diff, `dp deploy get/watch`, `dp kube get`, `dp sage query`, инспекция pipeline) выполняются без подтверждения. Production - повышенная осторожность: всегда показывай команду целиком и dry-run перед изменяющим действием.

## Предусловия

- Ветка `master`, рабочее дерево чистое.
- `git fetch --tags`; `master` обновлен из `origin` (`git merge --ff-only origin/master`).
- Доступны: `dp` CLI (плагины deploy, kube, sage, gitlab), `jq`, `git`; MCP dpGitlab, dpSage, dpKube, time.
- Если чего-то нет - остановись и попроси подключить, не выдумывай.

## Workflow

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

Сгруппируй по типам (Features / Fixes / Docs / Chore), описывай реальные изменения по изменённым файлам, добавь блок «Риски и наблюдения». Покажи draft, при необходимости прогони через `writing-russian-editor`, подтверди.

`CHANGELOG.md` в проекте нет и не заводим: changelog живет в сообщении annotated-тега (`git tag -n99 <tag>`, `git show <tag>`).

### 3. Feature flags (обязательный шаг)

Релиз может добавить новые remote-config флаги (`release.*`). Если флаг есть в коде, но не выставлен в thermostat, в prod пойдет ERROR `FLAG_NOT_FOUND` и фича резолвится в default.

Найди новые флаги в диапазоне релиза:

```bash
git diff <prev-release>..HEAD -- src/app/infrastructure/remote_config/params.py \
  | grep -E "^\+\s*key='release\." | sed -E "s/.*key='([^']+)'.*/\1/"
```

Для каждого нового флага инженер должен проверить в thermostat, **включен он или выключен**, и что это соответствует замыслу релиза. У `dp` нет плагина thermostat: проверка идет через web-UI thermostat. Runtime-сигнал незарегистрированного флага - Sage `FLAG_NOT_FOUND` (шаг 8 и smoke).

Затем - **явный gate через `AskUserQuestion`**: «Подтверди, что новые FF проверены в thermostat и выставлены как задумано (вкл/выкл)». Не двигайся к анонсу, пока инженер не подтвердил. Состояние флагов влияет на аудиторию анонса (шаг 9).

### 4. Annotated release-тег

Имя: `release-YYMMDD.HHMM` (текущее время выпуска). CI валидирует формат регуляркой `^(release|dev)-\d{6}\.\d{4}$` - 6-значная дата, 4-значное время. Сообщение тега = changelog (annotated, не lightweight).

```bash
git tag -a release-YYMMDD.HHMM -F <changelog-file> <commit>
git cat-file -t release-YYMMDD.HHMM   # ожидаем: tag
```

Перед `git push origin <tag>` - **`AskUserQuestion`**.

### 5. GitLab tag-pipeline

После push найди pipeline через dpGitlab (branch == имя тега), дождись терминального статуса. На теге выполняются только build-job'ы (`build-test`, `build` - сборка образа `dwsai/dwsai-data-agent:<tag>`); тесты/линт/type-check привязаны к MR и default-branch, на тег не запускаются. Red → стоп, покажи логи упавшего job, предложи шаг. Удобно поллить в фоне:

```bash
dp gitlab pipeline -t dwsai -r dwsai-data-agent -i <pipeline-id>
```

### 6. Deploy через spirit-deploy

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

Перед `dp deploy do` (production) - **`AskUserQuestion`**.

### 7. Мониторинг (dpKube + dpSage)

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

### 8. Post-release smoke

```bash
RELEASE_TAG=release-YYMMDD.HHMM scripts/release_smoke.sh
```

Скрипт (read-only, на `dp kube`/`dp sage`) проверяет: образ всех подов == release-тег, все ready, restarts в пределах порога (оба кластера); новые `release.*` флаги в диффе (предупреждение - проверить в thermostat); Sage error-delta (новые ERROR-сигнатуры против прошлого релиза). FAIL на error-delta = нужна ручная триажа: безобидное (как FLAG_NOT_FOUND → тикет) или реальная регрессия (→ rollback).

### 9. Проверка задач в JIRA (Done)

После верификации релиза на проде сверь, что все задачи, вошедшие в релиз, в статусе `Done`.

- Собери тикеты релиза: `git log --format='%s%n%b' <prev>..<cur> | grep -oiE '(DWSAI|DGP|DC)-[0-9]+' | sort -u`; при необходимости добавь тикеты из веток и описаний MR (`dp_gitlab_merge-requests`).
- Для каждого тикета проверь статус через `dp_jira_issue` (skill `jira-team-workflow`).
- Не-`Done` задачи переводи в `Done` (поток `RELEASE PREPARATION → DONE`) только после подтверждения через `AskUserQuestion`.
- MR без связанного тикета отметь как наблюдение (изменение без задачи), тикет не выдумывай.

### 10. Анонс в Time (2 аудитории, 2 канала)

Авто-постинга нет: готовь текст, публикует инженер или ты только после **`AskUserQuestion`**. Перед постом в канал сделай тест-доставку себе в личку (`dm` на свой username) и проверь, как пришло форматирование (Mattermost-markdown).

Лимит сообщения Time - 4000 символов. Если release note длиннее, уменьшай его, а длинные Sage deep-ссылки (`message=`) выноси отдельно: в реальном канале - в тред к основному посту (`create_post` с `root_id`), не в тело сообщения.

Каналы и аудитории:

- **Инженерам** - канал `dws-ai-agent` (https://time.tbank.ru/tinkoff/channels/dws-ai-agent): технический отчет о релизе.
- **Пользователям** - канал `~dwsai-announcement` (public, id `dspn99zritbs7duks3g4skjc6r`): анонс на языке пользователя. Приложение называй user-facing именем **Nessy Data Agent**, а не внутренними `data-agent` / `data-agent-prod`.

Правило аудитории по feature flags (шаг 3): фичу за выключенным в prod флагом в пользовательский анонс НЕ включай, она идет только инженерам. Если включенных user-facing изменений нет (релиз внутренний), не выдумывай их: дай пользователям минимальную строку или согласуй пропуск user-анонса.

Инженерный анонс делай по полному формату из [references/engineer-release-note-template.md](references/engineer-release-note-template.md) - 12 секций: заголовок `## Production release: data-agent <tag>`, предыдущая версия и статус, Links, Поставка, Runtime impact, Health-check, Feature ownership, Feature flags, Environment variables, Changelog, Known issues / follow-ups, Логи. Кратко:

- Ссылки кликабельные: pipeline, compare `<prev>...<cur>`, tags, Spirit Deploy (revision), Sage, Grafana.
- Таблицы Feature ownership (Area / Change / Jira / MR / Contact / Runtime action) и Feature flags заполняй реальными данными: MR и авторы через `dp_gitlab_merge-requests` (match по заголовку коммита), assignee через `dp_jira_issue`. Пробелы помечай `TODO` / `не указано`, не выдумывай MR, владельцев, флаги и env.
- Known issues: ошибки списком, каждая со ссылкой на свой тип в Sage (фильтр `message=` с экранированием, `env:"prod"`, `start=-1d`).

Шаблон пользователям (канал `~dwsai-announcement`):

```
**Nessy Data Agent - обновление**

Что нового:
- <user-facing изменение, только если флаг включен в prod>
- <...>

<если включенных user-facing изменений нет:>
В этом обновлении - внутренние улучшения надежности и наблюдаемости. Заметных изменений в работе агента нет.
```

### 11. Rollback guardrail

При провале деплоя или критической регрессии - не откатывай молча. Подготовь план, покажи команду, спроси через **`AskUserQuestion`**, и только потом:

```bash
dp deploy rollback --tenant dwsai --app data-agent-prod
```

Лог-шум (как FLAG_NOT_FOUND с fallback на default) при здоровом сервисе - не повод для rollback, а кандидат на отдельный тикет.

## Итоговый отчет

В конце релиза верни: release-тег, changelog, статус pipeline, статус deploy (ревизия), результат мониторинга, результат smoke, проверенные FF, статусы задач JIRA (все ли Done), путь к анонсам, оставшиеся ручные действия.

## Константы проекта

- tenant: `dwsai`; репозиторий: `dwsai-data-agent`
- Spirit Deploy app: `data-agent-prod`; компонент: `data-agent-webservice-prod`; serviceId: `a5392cc8-c3fd-4512-82d4-5394623f6be5`
- namespace: `dwsai-data-agent-prod-prod-daas`; кластеры: `bm-ix-m5-inside-wl1.prod`, `bm-ix-m5-inside-wl4.prod`
- imageStream: `docker-hosted.artifactory.tcsbank.ru/dwsai/dwsai-data-agent`
- Sage: group `dwsai`, system `data-agent`, env `prod`
- CI tag-регулярка: `^(release|dev)-\d{6}\.\d{4}$`
- Time-каналы: инженерам `dws-ai-agent` (https://time.tbank.ru/tinkoff/channels/dws-ai-agent); пользователям `~dwsai-announcement` (id `dspn99zritbs7duks3g4skjc6r`, public)
- User-facing имя приложения для анонсов: `Nessy Data Agent` (внутренние имена `data-agent` / `data-agent-prod` в user-анонс не выносить)
