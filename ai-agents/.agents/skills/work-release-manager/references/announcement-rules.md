# Release announcements - общие правила

Общие правила для всех артефактов анонса релиза dwsai-data-agent: status
taxonomy, распределение информации, язык, ссылки, неизвестные данные, секреты.
На этот файл ссылаются шаблоны time-post / thread / user-announcement /
release-manifest и SKILL.md.

Базовый стиль: без эмодзи, без рекламного тона, риски не скрывать, факты не
выдумывать. Дефисы, не em dash. English section headers + русский body.

## Status taxonomy

Каждый технический артефакт (Time post, thread, manifest) несет ровно один
статус. Итоговый отчет релиза присваивает его.

- `Delivered / Healthy` - релиз доставлен, rollout завершен, сервис healthy,
  known issues нет.
- `Delivered / Known issue` - доставлен, есть issue, но подтвержденного влияния
  на пользователя/сервис нет (log noise, fallback default, minor warning,
  не блокирующая проблема feature flag).
- `Delivered / Degraded` - доставлен, есть подтвержденное или вероятное влияние
  (рост 5xx, деградация latency, сломанный критичный flow, деградация ключевой
  метрики).
- `Rollback in progress` - rollback начат, не завершен.
- `Rolled back` - production возвращен на rollback target.
- `Delivery failed` - pipeline/deploy/rollout упал, релиз не доставлен.

## Information distribution

Что в какой артефакт идет. Не дублировать без операционной необходимости.

| Информация               | Time post                | Thread          | User announ.      | Manifest         |
| ------------------------ | ------------------------ | --------------- | ----------------- | ---------------- |
| Service + release tag    | обяз.                    | опц.            | опц.              | обяз.            |
| Status                   | обяз.                    | если изменился  | нет               | обяз.            |
| Previous release         | обяз.                    | нет             | нет               | обяз.            |
| Rollback target          | обяз.                    | при issue       | нет               | обяз.            |
| User impact              | обяз.                    | опц.            | обяз. если есть   | обяз.            |
| Compact links            | обяз.                    | опц.            | нет               | обяз.            |
| Long Sage links          | нет                      | при наличии     | нет               | обяз.            |
| Changelog                | обяз.                    | нет             | только user-видим | обяз.            |
| Owners                   | в буллетах changelog     | при issue       | нет               | обяз.            |
| MR/Jira links            | только если action-crit. | опц.            | нет               | если доступно    |
| DB migrations            | summary                  | нет             | нет               | обяз.            |
| Secrets/runtime config   | summary                  | нет             | нет               | обяз.            |
| Feature flags            | только изм./проблемные   | при issue       | нет               | если изм./пробл. |
| Known issues             | если есть                | детально        | только user-видим | обяз.            |
| Post-release observation | кратко                   | обяз. если тред | нет               | обяз.            |
| Docs/Chore               | компактно                | нет             | нет               | обяз.            |

Main Time post читается за 2-3 минуты.

## Language

Технические артефакты (Time post, thread, manifest):

- section headings, status names, field names - English;
- body - русский;
- code identifiers и system names - без изменений;
- одобренные английские технические термины остаются на английском (глоссарий
  `writing-russian-editor`).

Допустимые английские термины: release, production, pipeline, deploy, rollout,
rollback, revision, tag, commit, branch, MR, compare, changelog, runtime, config,
secret, feature flag, fallback default, API, endpoint, middleware, SDK, CLI, pod,
cluster, restart, health-check, logs, metrics, dashboard, error, warning,
critical, known issue, follow-up, owner.

Не писать: «релиз задеплоен», «поды зароллились», «по двум flags», «вероятный
trigger». Писать: «релиз доставлен в production», «rollout завершен», «два
feature flag», «вероятная причина».

User announcement - только русский, без лишних англоязычных implementation-
терминов; user-facing продуктовые имена остаются (Nessy Data Agent, Helicopter,
datacheck); объяснять эффект, не реализацию.

## Link policy

- Time post: compact links одной строкой - Pipeline, Compare, Deploy, Logs,
  Manifest. Без длинных Sage URL, без всех MR/Jira/tag-ссылок.
- Thread: длинные Sage deep-ссылки, сгруппированные по типу ошибки, metric-
  ссылки, follow-up investigation.
- Manifest: все релевантные ссылки - pipeline, compare, current/previous tag,
  deploy, logs, dashboard, MR, Jira, Sage по known issues.

## Unknown / missing data

Неизвестное не выдавать за факт. Нет данных - явная формулировка: `unknown`,
`not checked`, `not available`, `не удалось подтвердить`. Не выкидывать строку
молча.

Хорошо: «DB migrations: `unknown`, не удалось подтвердить по diff». Плохо:
«DB migrations: нет» (когда не проверял).

## Secrets

Значения secret-переменных и токенов не рендерить ни в одном артефакте. В env-
таблицах manifest - только имя, факт изменения, required/secret-флаг.
