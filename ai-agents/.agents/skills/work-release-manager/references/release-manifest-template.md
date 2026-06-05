# Release manifest (wiki)

Полная техническая запись production-релиза. Создается на каждый релиз дочерней
страницей к `04 – Release Manifest` (id `8451788585`, space DW). Общие правила -
[announcement-rules.md](announcement-rules.md).

Заголовок страницы (дефисы, не em dash):

```
YYYY-MM-DD - data-agent - <release-tag>
```

Пример: `2026-06-04 - data-agent - release-260604.2203`.

Плоская таксономия: без вложенности по году/месяцу, все manifest - прямые дети
parent-страницы.

## Секции (8)

### 1. Summary

| Field            | Value                                   |
| ---------------- | --------------------------------------- |
| Service          | data-agent                              |
| Release          | <release-tag>                           |
| Previous release | <previous-release>                      |
| Status           | <release-status>                        |
| Production state | <healthy / degraded / failed / unknown> |
| Rollback target  | <previous-release>                      |
| User impact      | <сводка>                                |
| Known issues     | <сводка>                                |

### 2. Links

| Type         | Requirement   | Value |
| ------------ | ------------- | ----- |
| Pipeline     | обяз.         |       |
| Compare      | обяз.         |       |
| Current tag  | обяз.         |       |
| Previous tag | обяз.         |       |
| Deploy       | обяз.         |       |
| Logs         | обяз.         |       |
| Dashboard    | если доступно |       |
| Jira         | если доступно |       |
| MR           | если доступно |       |

Ссылки нет - `unknown` / `not available`, строку не выкидывать молча.

### 3. Ops

| Area                   | Status                              | Details         |
| ---------------------- | ----------------------------------- | --------------- |
| Pipeline               |                                     |                 |
| Deploy                 |                                     | <revision>      |
| Image                  |                                     |                 |
| Rollout                |                                     | <pods/clusters> |
| Pods                   |                                     | <ready count>   |
| Restarts               |                                     | <count>         |
| Startup event          |                                     |                 |
| Warning events         |                                     |                 |
| DB migrations          | <none / present / unknown>          |                 |
| Secrets/runtime config | <none / changed / unknown>          |                 |
| Feature flags          | <none / changed / known issue / unknown> |            |
| Performance impact     | <none / detected / unknown>         |                 |
| Rollback target        | <ready / unknown>                   | <release>       |

### 4. Changelog

Списки, не таблицы. Группы Features / Fixes / Docs / Chore. Каждый пункт:

- <описание>. Owner: @owner. MR: <ссылка если есть>. Jira: <ссылка если есть>.

### 5. Ownership

| Area   | Owner  | Notes |
| ------ | ------ | ----- |
| <area> | @owner |       |

### 6. Known issues

| Issue   | Impact   | Owner  | Action   | Links  |
| ------- | -------- | ------ | -------- | ------ |
| <issue> | <impact> | @owner | <action> | <Sage> |

Все known issues, включая low-impact. Sage-ссылки прикладывать.

### 7. Post-release observation

| Time      | Status           | Result | Notes |
| --------- | ---------------- | ------ | ----- |
| T+2-3 min | <status>         |        |       |
| T+30 min  | <status/pending> |        |       |

### 8. Follow-ups

| Action   | Owner  | Status                    |
| -------- | ------ | ------------------------- |
| <action> | @owner | <TODO / In progress / Done> |

## Где брать данные

Из шагов 1-9 релизного workflow: tags (`git tag`), pipeline (dpGitlab), compare и
tags (GitLab URL), deploy/revision (`dp deploy do`), MR и авторы
(`dp_gitlab_merge-requests`), Jira и assignee (`dp_jira_issue`), ops (dpKube),
Sage (dpSage). Секреты не рендерить.
