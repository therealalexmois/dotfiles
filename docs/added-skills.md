# Добавленные skills (2026-06-04)

Источник: [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) (форки и адаптации, часть — производные от `mattpocock/skills`).

Все skills лежат в источнике правды `ai-agents/.agents/skills/<name>/` и слинкованы в оба CLI:
`~/.claude/skills/<name>` и `~/.codex/skills/<name>` (через `~/.agents/skills/<name>` → dotfiles).

> **Важно:** skills подгружаются при старте CLI. Новые станут доступны **после перезапуска**
> Claude Code / Codex. Проверить список — `/` (Claude) или раздел skills в Codex.

## Как пользоваться

Skill срабатывает двумя способами:

1. **По триггеру** — пишешь запрос естественным языком, в котором есть слова из `description`
   skill'а (например «review my diff», «plan a release»). CLI сам подхватывает нужный skill.
2. **Явно** — командой `/<имя-skill>` в Claude Code.

Скрипты внутри skill'ов (`*.py`) запускаются самим агентом по инструкции из `SKILL.md`;
вручную их дёргать не нужно.

---

## Каталог (15 skills)

### Дисциплина кода и ревью

#### `karpathy-coder`
Применяет 4 принципа Карпатого: выявить допущения до кода, держать просто, делать
хирургические правки, задавать проверяемую цель.
- **Use cases:** ревью своего diff, проверка на переусложнение, гейт перед коммитом.
- **Триггеры:** «review my diff», «check complexity», «am I overcomplicating this»,
  «karpathy check», «before I commit».
- **Пример:** `review my diff before I commit` → агент прогонит diff через
  `complexity_checker.py` / `assumption_linter.py` и вернёт список переусложнений и
  непроверенных допущений.

#### `api-design-reviewer`
Ревью дизайна REST API: линтинг конвенций, детект breaking changes, скоркарта качества.
- **Use cases:** PR с новыми/изменёнными эндпоинтами, аудит API перед миграцией на v2,
  установка командных стандартов API.
- **Пример:** `review the API changes in this PR` → отчёт о нарушениях конвенций,
  отсутствии версионирования и потенциальных breaking changes.

#### `tech-debt-tracker`
Сканирует кодовую базу на технический долг, оценивает серьёзность, отслеживает тренды,
строит приоритизированный план устранения.
- **Use cases:** оценка code health, планирование cleanup-спринтов, модернизация legacy,
  оценка стоимости поддержки.
- **Пример:** `scan this repo for tech debt and prioritize it` → таблица долга с оценкой
  severity и планом ремедиации.

### Проработка плана (grilling)

#### `grill-me`
Безжалостно интервьюирует по плану/дизайну, по одному вопросу, спускаясь по дереву решений
до общего понимания.
- **Use cases:** стресс-тест плана перед реализацией, разбор архитектурного решения.
- **Пример:** `grill me on this migration plan`.

#### `grill-with-docs`
То же, но привязано к документации проекта: сверяет план с языком домена (`CONTEXT.md`) и
зафиксированными решениями (`docs/adr/`), обновляет эти файлы по ходу.
- **Use cases:** стресс-тест плана против документированного домена, поддержание ADR в
  актуальном состоянии.
- **Пример:** `grill with docs: я хочу переименовать сущность Order в Deal`.
- *Заменил прежнюю версию из `mattpocock/skills` на более полную (добавлены `references/`,
  `scripts/` с линтерами CONTEXT.md/ADR/глоссария).*

### Релизы и CI/CD

#### `release-manager`
Планирование релизов, ведение changelog, координация деплоя, релизные ветки, версионирование.
- **Use cases:** план релиза, версионный бамп (semver), hotfix-процедуры.
- **Пример:** `plan the next release from main` → план релиза + bump версии +
  сгенерированный changelog (`release_planner.py`, `version_bumper.py`).

#### `changelog-generator`
Генерирует аудируемые release notes из Conventional Commits; разделяет парсинг коммитов,
логику semver-бампа и рендер changelog.
- **Use cases:** нарезка релиза, генерация `CHANGELOG.md` из git-истории, автоматизация в CI.
- **Пример:** `generate CHANGELOG.md from git history since v1.2.0`.

#### `ci-cd-pipeline-builder`
Строит прагматичные CI/CD-пайплайны по сигналам стека проекта: быстрый baseline,
повторяемые проверки, среды деплоя.
- **Use cases:** CI для нового проекта, рефакторинг пайплайнов, стандартизация деплоя по репо.
- **Пример:** `set up CI for this project` → черновой пайплайн под обнаруженный стек.

### Эксплуатация и наблюдаемость

#### `runbook-generator`
Генерирует операционные runbook'и по имени сервиса: деплой, реакция на инциденты,
обслуживание, откат. Шаблон настраивается под окружение.
- **Use cases:** on-call процедуры для нового сервиса, стандартизация incident response,
  runbook перед выходом в прод.
- **Пример:** `generate a runbook for the payments service`.

#### `observability-designer`
Проектирует стратегию наблюдаемости (метрики, логи, трейсы): SLI/SLO, golden signals,
оптимизация алертов.
- **Use cases:** добавление observability в новый сервис, борьба с шумными алертами,
  построение SLO-программы перед ростом нагрузки.
- **Пример:** `design SLOs and golden-signal alerts for this API`.

### Данные

#### `database-schema-designer`
Проектирование схем БД: ERD-диаграммы, нормализация, связи таблиц, план миграций.
- **Use cases:** новая схема, нормализация существующей, планирование миграций.
- **Пример:** `design an ERD for an orders + payments domain`.

### Агенты и автоматизация

#### `agent-designer`
Проектирование мультиагентных систем: архитектура, паттерны коммуникации, автономные
воркфлоу. Содержит планировщик, генератор tool-схем, оценщик агентов.
- **Use cases:** дизайн мультиагентной системы, определение протоколов взаимодействия.
- **Пример:** `design a multi-agent system for automated code review`.

#### `agent-workflow-designer`
Production-grade мультиагентные воркфлоу: выбор паттерна (sequential / parallel /
hierarchical), контракты передачи, обработка отказов, контроль стоимости и контекста.
- **Use cases:** архитектура многошагового пайплайна, выбор single- vs multi-agent,
  рефакторинг воркфлоу со «вздутым» контекстом.
- **Пример:** `should this be one agent or a pipeline? design the workflow`.

#### `autoresearch-agent`
Автономный цикл экспериментов: правит целевой файл, гоняет фиксированную оценку,
улучшения коммитит, провалы откатывает (`git reset`) — и так в цикле. Вдохновлён
autoresearch Карпатого.
- **Требует:** целевой файл, команду оценки с числовой метрикой, git-репо.
- **Use cases:** оптимизация скорости кода, размера бандла/образа, прохождения тестов,
  промптов, качества контента (заголовки, copy, CTR).
- **Пример:** `optimize bundle.js for size; eval = "npm run build:size"` → агент крутит
  цикл правка → оценка → keep/reset.
- *Из upstream взят основной skill; под-skills плагина (resume/setup/status/run/loop) и
  каталог `evaluators/` не добавлялись.*

### Безопасность

#### `skill-security-auditor`
Аудит и сканер уязвимостей для AI-агентских skills **перед установкой**: опасные паттерны
(`os.system`, `eval`, `subprocess`, сетевой эксфильтрейт), prompt injection в `SKILL.md`,
риски цепочки зависимостей, выход за границы ФС.
- **Use cases:** оценка skill из недоверенного источника, pre-install гейт для
  Claude Code / Codex skills, аудит git-репо со skill'ами.
- **Пример:** `audit this skill before I install it: <path или git-url>`.
- **Рекомендация:** прогонять этим skill'ом любой новый сторонний skill (включая
  добавленные здесь) перед доверием.

---

## Откат

Удалить отдельный skill:

```sh
S=<имя>
rm -rf ~/.dotfiles/ai-agents/.agents/skills/$S
rm -f ~/.agents/skills/$S ~/.claude/skills/$S ~/.codex/skills/$S
```
