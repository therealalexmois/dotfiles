# User-facing announcement (канал ~dwsai-announcement)

Только user-видимые изменения. Генерировать, только если user impact не «none».
Общие правила - [announcement-rules.md](../references/announcement-rules.md).

Язык - русский. Приложение - `Nessy Data Agent` (не внутренние `data-agent` /
`data-agent-prod`). Продуктовые имена, знакомые пользователю (Helicopter,
datacheck), допустимы. Объяснять эффект, не реализацию.

Правило аудитории по feature flags: изменение за выключенным в prod флагом в
user announcement НЕ включать - оно идет только инженерам.

## Структура

```
**Nessy Data Agent - обновление**

## Что изменилось
- <user-видимое изменение>

## Что это даёт
- <короткая польза>

## Нужно ли что-то сделать
<нет / требуемое действие>

## Ограничения
<известные user-facing ограничения / нет известных ограничений>
```

## Не включать

pipeline, deploy, GitLab, Sage, Kubernetes, pods, rollout, rollback target,
внутренние runtime-детали, изменения eval-харнесса, docs/chore (кроме случая,
когда есть релевантная пользовательская документация).

## Нет user impact

Если включенных user-facing изменений нет - не выдумывать. Вывести ровно строку
(в чат, в канал не постить):

```
User-facing announcement is not required: no user impact.
```
