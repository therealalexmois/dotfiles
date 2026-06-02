## Чеклист

- [x] Заголовок MR соответствует формату `type(scope): сделал изменение`
- [ ] Локальные проверки пройдены: `just project-check`
- [x] Если менял конфиги / деплой / интеграции — приложил детали ниже

---

## Что и зачем изменено

- Добавил grader-only MVP eval-харнесс в `scripts/agent_eval`: CLI с командами `eval`, `grade`, `view`, `check`, `benchmark`, вызов streaming-эндпоинта агента, обработка SSE-событий, preflight-проверки, grader-based оценка assertions и HTML-отчёт.
- Покрыл поведение харнесса тестами в `tests/agent_eval` (CLI, grading, io, preflight, runner, streaming, viewer, benchmark).
- Добавил eval-кейсы для skill-creator в `skills/skill-creator/evals` (`behavior.json`, `README.md`).
- Добавил в `Makefile` цели `eval-run`, `eval-grade`, `eval-view`, `eval-check`, `eval-benchmark`, `eval-diff` для запуска харнесса локально.
- Добавил в `pyproject.toml` исключение `scripts/agent_eval` в `extend_exclude` для deptry (харнесс — отдельная developer-тулза вне зависимостей продакшн-кода).
- Продакшн runtime, API-контракты, конфиги/env, миграции и CI не менялись.

---

## На что обратить внимание

- [ ] Менялся API-контракт
- [ ] Менялись конфиги / env / secrets
- [ ] Менялась CI/CD логика
- [ ] Есть миграция БД
- [ ] Нужны post-deploy проверки
- [x] Нет особенностей

---

## Ручная проверка

- [x] Не требуется

---

## Связанное

- Jira: ...
- RFC / дизайн: ...
- Документация: `docs/agent/evals.md`, `scripts/agent_eval/README.md`
