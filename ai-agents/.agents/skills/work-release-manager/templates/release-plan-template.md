# Release plan (план-гейт перед тегом)

Артефакт шага 4: собирается из фактов шагов 0-3 и показывается на approve ДО
создания тега. Живет в чате, в Time/wiki не публикуется; итоги попадают в
manifest и анонсы. Общие правила -
[announcement-rules.md](../references/announcement-rules.md).

Для hotfix план обязателен тоже, в короткой форме; особое внимание секции
Scope - «попутчики» из `master` едут вместе с фиксом.

## Структура

```
## Release plan: data-agent <candidate-tag>

**Previous release**: <previous-release>
**Rollback target**: <previous-release>
**Head commit**: <sha>

---

### Scope
- **Commits**: <N> (<files> files, +<ins>/-<del>)
- **Tickets**: <DWSAI-... / нет>
- **Changelog (draft)**:
  - **Features**: <кратко>
  - **Fixes**: <кратко>
  - **Docs / Chore**: <кратко>

---

### Operational impact
- **DB migrations**: <none / present / unknown>
- **Secrets/runtime config**: <none / changed: имена без значений / unknown>
- **Feature flags**: <none / changed: флаги + состояние thermostat / unknown>
- **API breaking changes**: <none / present / unknown>

---

### Риски и наблюдения
- <риск или наблюдение / не выявлены>

---

### Анонсы
- **Manifest**: обязателен (шаг 11).
- **Time post + thread**: шаг 12.
- **User announcement**: <будет: есть user impact / не нужен: no user impact> (шаг 13).

---

### Необратимые шаги впереди
- git push <candidate-tag>
- dp deploy do (production)
- создание wiki manifest
- посты в Time
- перевод JIRA в Done
```

## Правила

- Факты - только из скриптов (`preflight_release.sh`, `collect_release_diff.sh`,
  детекторы шага 3) и MCP; ничего не выдумывать, неизвестное - `unknown`.
- Вводные метки перед двоеточием жирные, перечисления списком (как в
  [time-post-template.md](time-post-template.md)).
- Approve через `AskUserQuestion`. После approve scope не менять молча: HEAD
  сдвинулся - перегенерировать план и переподтвердить.
- Секреты не показывать: для env только имена.
