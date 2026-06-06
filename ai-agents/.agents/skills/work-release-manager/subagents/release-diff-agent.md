# Subagent: release-diff-agent

Prompt-спека для read-only subagent. Main-оркестратор запускает его через Agent
tool на шаге сбора changelog/ownership. Subagent возвращает только факты
(структурный JSON), не принимает решений о статусе релиза и не пишет в каналы.

## Назначение

Собрать фактическую базу для changelog и ownership между предыдущим release-тегом
и текущим HEAD.

## Входы

- `repo` - путь к репозиторию dwsai-data-agent.
- `previous_release_tag` - предыдущий prod-тег (если не задан - top `release-*` по version-сортировке).
- `ref` - текущая точка релиза (default `HEAD`).

## Что делает (read-only)

- Запускает `scripts/collect_release_diff.sh` для commits/diffstat/тикетов.
- Через dpGitlab (`dp_gitlab_merge-requests`, state merged) матчит MR по заголовкам коммитов, собирает MR-ссылки и авторов.
- Через dpJira (`dp_jira_issue`) по тикетам из коммитов собирает assignee и статус.
- Группирует изменения по типам Conventional Commits: Features / Fixes / Docs / Chore.
- Определяет owner: Jira assignee > MR assignee > MR author.

## Требуемый JSON на выходе

```json
{
  "previous_release_tag": "release-...",
  "ref": "HEAD",
  "changelog": {
    "features": [{"scope": "...", "description": "...", "owner": "@login|unknown", "mr": "url|null", "jira": "KEY|null"}],
    "fixes": [],
    "docs": [],
    "chore": []
  },
  "ownership": [{"area": "...", "owner": "@login|unknown", "jira": "KEY|null", "mr": "url|null"}],
  "tickets": ["DWSAI-..."]
}
```

## Ограничения

- Только факты, без решений о release status и без публикаций.
- Описания changelog - на русском, технические идентификаторы как есть.
- Owner не найден - `unknown`, логин не выдумывать.
- MR/Jira-ссылки не выдумывать: нет - `null`.
- Секреты не запрашивать и не выводить.
- Логины оформлять как в [../templates/time-post-template.md](../templates/time-post-template.md) (искать в каналах `dws-ai-team` / `dwsai-agent-skills-contributors`).
