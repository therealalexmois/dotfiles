# Инженерный release note (шаблон и правила)

Канал: `dws-ai-agent`. Стиль: формально, кратко, без эмодзи, без рекламного тона. Риски не скрывать. Факты не выдумывать: нет данных - `TODO:` или `не указано`.

## Обязательная структура

1. `## Production release: <service> <current_release>`
2. Предыдущая версия + статус
3. `### Links`
4. `### Поставка`
5. `### Runtime impact`
6. `### Health-check`
7. `### Feature ownership`
8. `### Feature flags`
9. `### Environment variables`
10. `### Changelog`
11. `### Known issues / follow-ups`
12. `### Логи`

## Где брать данные (без выдумывания)

- current/previous release: `git tag -l 'release-*' --sort=-version:refname`.
- pipeline: dpGitlab, WebURL пайплайна тега.
- compare: `https://gitlab.tcsbank.ru/dwsai/dwsai-data-agent/-/compare/<prev>...<current>`.
- tags: `https://gitlab.tcsbank.ru/dwsai/dwsai-data-agent/-/tags/<tag>`.
- deploy/revision: вывод `dp deploy do` (devplatform URL с `?revision=`).
- MR и авторы: `dp_gitlab_merge-requests` (state merged), match по заголовку коммита из `git log <prev>..<cur>`.
- Jira и assignee: `dp_jira_issue` по тикету из коммита/ветки.
- health dashboard: Grafana workloads из `application.yaml` (поле `sageUrl`/grafana).
- Sage logs: см. раздел «Логи».

## Links

GitLab pipeline, GitLab compare `prev → current`, current tag, previous tag, Spirit Deploy, Sage logs, Grafana/health dashboard, rollback playbook. Нет ссылки - `TODO: добавить ссылку`. Сформированные по схеме URL (compare/tags) помечать «проверить».

## Runtime impact

- API breaking changes: `yes/no/не указано`
- DB migrations: `yes/no/не указано`
- New feature flags: `yes/no/не указано`
- New env vars: `yes/no/не указано`
- Rollback target: `<previous_release>`

## Feature ownership

| Area | Change | Jira | MR | Contact | Runtime action |
| ---- | ------ | ---- | -- | ------- | -------------- |

- Contact: Jira assignee > MR assignee > MR author; нет данных - `TODO: определить`.
- Owner оформляй как `@login` (Time mention). Логины ищи прежде всего в участниках канала `dws-ai-team`, для внешних контрибьюторов - `dwsai-agent-skills-contributors`. Бери через `get_channel_members` + `get_users_info` (match по display name автора коммита/MR). Если человека нет в каналах и `search_users` даёт неоднозначный результат - оставь имя без `@`, логин не выдумывай.
- Runtime action кратко: `No action`, `Check flag`, `Register flag`, `Validate env`, `TODO`.

## Feature flags

| Flag | Change | Default | Prod value | Contact | Action |
| ---- | ------ | ------: | ---------: | ------- | ------ |

- Показывать новые, изменённые и проблемные флаги. Незарегистрированный в Thermostat флаг указывать явно.
- Неизвестное значение - `unknown`. Нет флагов - `Новых или изменённых feature flags не указано.`
- Детект новых: `git diff <prev>..<cur> -- src/app/infrastructure/remote_config/params.py | grep "^\+[[:space:]]*key='release\."`.
- Runtime-сигнал незарегистрированного флага: Sage `FLAG_NOT_FOUND`.

## Environment variables

| Variable | Change | Required | Secret | Contact | Action |
| -------- | ------ | -------: | -----: | ------- | ------ |

- Значения secret-переменных не показывать. Нет env vars - `Новых или изменённых environment variables не указано.`
- Детект: `git diff <prev>..<cur> -- deploy/service.yml` (секция `envs`).

## Changelog

Группы `Features` / `Fixes` / `Docs` / `Chore`. Формулировки инженерные и короткие. Без разговорных слов (`ок`, `шумок`, `доехало`, `заведем`). Не склонять английские названия компонентов через дефис.

## Known issues / follow-ups

Для каждой проблемы: что произошло, причина (если известна), влияние на сервис, ответственный (если известен), follow-up action, ссылка на задачу (нет - `TODO: создать задачу`). Прикладывать Sage-ссылки по типу ошибки (см. «Логи»).

## Логи (Sage)

- Общий ERROR за сутки: `https://sage.tcsbank.ru/search?start=-1d&end=now&query=group%3D%22dwsai%22+system%3D%22data-agent%22+env%3A%22prod%22+level%3D%22ERROR%22`.
- Ссылка на конкретный тип ошибки: добавить в query `message="<точное сообщение>"`. Вложенные кавычки внутри message экранировать как `\"` (иначе UI Sage даст Illegal syntax). Полезно добавить `version="<release-tag>"`, чтобы привязать к релизу.
- Период `start=-1d`: ночью трафика нет, за час ссылка может быть пустой.
- Особенности синтаксиса:
  - free-text не поддерживается, фильтровать только по полям (`message=`, `request_id=`, `version=`).
  - в UI-ссылке среда через двоеточие: `env:"prod"`. В `dp sage query` (MageQL) работает `env="prod"`.
- Сборку длинного URL делать через urlencode (например `python3 -c "import urllib.parse as u; print(u.quote_plus(q))"`), не вручную.
- Лимит сообщения Time - 4000 символов. Полный note с таблицами часто не влезает: дроби на части и выноси длинные Sage deep-ссылки отдельным сообщением; в реальном канале - в тред к основному посту (`create_post` с `root_id`).
