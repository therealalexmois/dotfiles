# Техническая терминология

## Принцип

Сохраняй точность, а не максимальное количество английских слов. Этот файл -
allowlist и набор правил, а не требование использовать каждый термин.

Оставляй термин, если он:

- является идентификатором, именем продукта, технологии, API или протокола;
- закреплен в проекте;
- точнее русского аналога;
- понятен целевой аудитории;
- явно сохранен пользователем.

## Обычно сохранять

### AI и ML

`AI`, `LLM`, `RAG`, `embedding`, `evaluation`, `benchmark`, `grounding`,
`tool call`, `agent`, `skill`, `MCP`, `latency`, `trace`, `span`, `prompt`,
`context window`, `fine-tuning`, `inference`.

### Software и инфраструктура

`runtime`, `thread`, `cache`, `middleware`, `payload`, `feature flag`,
`use case`, `migration`, `lock`, `connection pool`, `endpoint`, `backend`,
`frontend`, `rollback`, `deploy`, `commit`, `merge`, `MR`, `PR`, `RFC`, `ADR`,
`API`, `CI/CD`.

### Python и data

`Python`, `FastAPI`, `Pydantic`, `pytest`, `mypy`, `ruff`, `async`, `await`,
`fixture`, `mock`, `adapter`, `port`, `DTO`, `SQL`, `PostgreSQL`, `ETL`,
`Airflow`, `Kafka`.

## Русская конструкция

Не склоняй английский термин через дефис и не создавай гибридные определения.

Плохо:

```text
skill-ом
workflow-а
Router-компонент
backend-сервис
```

Лучше:

```text
с помощью skill
для workflow
компонент Router
сервис backend
```

Переписывай составные кальки:

```text
read-only endpoint -> endpoint только на чтение
backend-owned skill -> skill на стороне backend
post-deploy checks -> проверки после деплоя
request-scoped provider -> provider на время запроса
```

## Использовать русский эквивалент

Если точность не страдает, пиши:

```text
draft -> черновик
request -> запрос
scope -> границы задачи
controlled -> контролируемый
dispatch -> отправка, передача или публикация
owner -> владелец, если это не формальная роль
```

## Никогда не переводить

- имена файлов и пути;
- классы, функции, методы, поля и переменные;
- HTTP methods, API endpoints и payload keys;
- JSON и YAML keys;
- CLI commands;
- Jira keys;
- метрики, log events, feature flags и environment variables.

Проверяй один термин по всему тексту. Не используй несколько названий для одной
сущности ради разнообразия.
