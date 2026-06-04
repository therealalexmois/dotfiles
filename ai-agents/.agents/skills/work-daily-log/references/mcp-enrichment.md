# Обогащение артефактов через MCP

Как подтянуть заголовок и статус артефакта, чтобы ссылка в дейли читалась без открытия. Все вызовы только читают. Если MCP недоступен или артефакт не нашелся, ставь ссылку из контекста сессии и не выдумывай статус.

## JIRA - `dpJira`

Инструмент `dp_jira_issue`. Ключ из URL `https://jira3.tcsbank.ru/browse/DWSAI-767` - это часть после `browse/` (`DWSAI-767`).

Параметры для экономного запроса:

- `key`: `DWSAI-767`
- `compact`: `true`
- `only-fields`: `key,summary,status`

Из ответа бери `summary` и `status`. Формат ссылки в дейли:

```md
[DWSAI-767](https://jira3.tcsbank.ru/browse/DWSAI-767)
```

В секции **Jira** добавляй переход, если он был в сессии: `[DWSAI-767](url): Developing -> Review`. Заголовок задачи в скобки не вставляй, ссылка идет ключом - так принято в существующих заметках.

## GitLab MR - `dpGitlab`

Инструмент `dp_gitlab_merge-request`. URL вида `https://gitlab.tcsbank.ru/{tenant}/{repository}/-/merge_requests/{id}`.

Для основного репозитория проекта:

- `tenant`: `dwsai`
- `repository`: `dwsai-data-agent`
- `id`: номер MR (например `93`)
- `diff-limit`: `1` (диф не нужен для обогащения, минимизируй вывод)

Из ответа бери заголовок MR и состояние (merged / open / draft / closed), при необходимости статус pipeline. Формат ссылки:

```md
[MR !93](https://gitlab.tcsbank.ru/dwsai/dwsai-data-agent/-/merge_requests/93) — merged
```

Статус для секции **Artifacts** маппится в `draft / in-review / merged / shipped / abandoned / unknown`:

- открытый MR на ревью -> `in-review`
- черновик / WIP / на hold -> `draft`
- влитой -> `merged`
- закрытый без мержа -> `abandoned`
- не удалось определить -> `unknown`

## WIKI - `dpWiki`

Инструмент `dp_wixie_get`. Параметры:

- `url`: ссылка на страницу Confluence
- `format`: `md`

Бери заголовок страницы. Формат ссылки:

```md
[Заголовок страницы](url) — doc
```

Тело страницы целиком не тяни без нужды: для дейли достаточно заголовка.

## Ошибки и пропуски

- MCP-сервер недоступен -> ставь сырую ссылку из сессии, статус `unknown` или без статуса.
- Артефакт не найден (404, нет доступа) -> не выдумывай заголовок и статус, оставь ссылку как есть.
- Несколько Jira-инстансов: `dp_jira_issue` без `jira-instance` сам перебирает jira, jira2, jira3 и возвращает первый успешный.
