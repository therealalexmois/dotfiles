# SKILL.md Profile

## Purpose

Используй этот profile для создания и review agent skills.

Skill должен быть operational contract для одного bounded context и одного основного пользовательского intent.

## Classification

Определи тип skill:

- `reference` – style, rules или domain knowledge без write;
- `workflow` – пошаговый процесс;
- `dashboard` – read-only анализ;
- `writer` – изменяет files или artifacts;
- `side-effect` – пишет во внешние системы;
- `wrapper` – маршрутизирует к другим skills или tools.

Если тип неясен, считай это architecture smell.

## Naming

Имя должно:

- описывать пользовательскую задачу;
- использовать lowercase kebab-case;
- избегать `helper`, `manager`, `utils`, `tools` и слишком широкого `workflow`;
- не зависеть от внутреннего имени файла;
- совпадать с фактической ответственностью.

Если skill делает authoring и review, не называй его только `*-authoring`.

## Description

`description` должен содержать:

```text
what it does + when to use it + trigger context + important exclusion
```

Проверь:

- описано действие агента, а не абстрактная польза;
- есть реальные trigger phrases;
- side effects не скрыты;
- соседние skills отрезаны;
- description не обещает больше, чем workflow.

## Required boundaries

Для non-trivial skill добавь:

- `When to use`;
- `When not to use`;
- Inputs;
- Source policy;
- Workflow;
- Decision rules, если skill выбирает или маршрутизирует;
- Guardrails;
- Tool policy, если tools используются;
- Write policy, если есть writes;
- Output contract;
- Validation checklist;
- References.

Не добавляй секцию без применимого содержания.

## Package architecture

Используй принцип:

```text
SKILL.md = router + invariants + critical guardrails
references = details, contracts, profiles and examples
scripts = deterministic operations
evals = regression checks
assets = reusable output templates
```

Оставь один `SKILL.md`, если:

- один workflow;
- файл короткий;
- нет нескольких modes;
- нет длинных domain rules;
- safety rules должны быть видны сразу.

Используй references, если:

- есть несколько modes или profiles;
- есть длинные contracts или templates;
- есть редко используемые rules;
- `SKILL.md` приближается к 300–500 строкам.

Раздели на skills, если:

- разные пользовательские intents;
- разные write policies;
- разные external systems;
- разные confirmation gates;
- read-only и side-effect behavior смешаны;
- evals показывают routing failures.

Удаляй или объединяй skill, если:

- он дублирует соседний skill;
- нет отдельного trigger intent;
- нет своего output contract;
- он является только набором советов;
- он не улучшает стабильность выполнения.

## Workflow quality

Workflow должен:

- идти в порядке выполнения;
- иметь observable result на каждом шаге;
- не содержать скрытых решений;
- отделять high-risk operations;
- завершаться validation;
- не требовать угадывать, какой reference читать.

Плохо:

```text
Проанализируй задачу и подготовь полезный результат.
```

Хорошо:

```text
1. Прочитай config.
2. Определи target period.
3. Прочитай source files.
4. Извлеки completed outcomes.
5. Верни gaps по output contract.
6. Проверь, что данные не выдуманы.
```

## Source and write policy

Skill должен перечислять allowed и forbidden sources.

Если skill пишет:

- перечисли targets;
- запрети unrelated writes;
- добавь confirmation gate для external side effects;
- добавь duplicate check;
- добавь post-write verification;
- запрети silent migration.

## Neighbor skills

Назови соседние skills, если overlap неочевиден.

Проверь:

- нет двух skills с одинаковым write access;
- нет двух sources of truth для одного layout;
- нет скрытой зависимости;
- нет разных терминов для одного объекта;
- compatibility rule задан для legacy/current conflict.

## Evals

Для non-trivial skill создай `evals/evals.json`.

Минимум:

1. happy path;
2. missing или ambiguous input;
3. forbidden side effect;
4. routing;
5. output contract.

Для writer и side-effect skill добавь:

- duplicate prevention;
- conflicting sources;
- no write without confirmation;
- post-write verification;
- wrong mode.

Каждый eval содержит:

- `name`;
- `input`;
- `expected_behavior`;
- `forbidden_behavior`.

## Review severity

Используй:

- `BLOCKER` – unsafe behavior, конфликтующие rules, отсутствующая проверка или неверные writes;
- `MAJOR` – размытые границы, context bloat, дубли, слабый workflow или missing contracts;
- `MINOR` – wording и локальная читаемость.

Verdict:

- `APPROVE` – нет BLOCKER и MAJOR;
- `APPROVE WITH MINOR COMMENTS` – только MINOR;
- `REQUEST CHANGES` – есть MAJOR, но нет критического unsafe gap;
- `REJECT / REWRITE` – есть BLOCKER или skill не работает как contract.

## Review checks

### Architecture

- Один bounded context.
- Один основной intent.
- Тип skill понятен.
- Соседние skills отрезаны.
- Read-only и writes не смешаны без причины.

### Metadata

- Имя соответствует задаче.
- Description содержит triggers и exclusions.
- Side effects не скрыты.

### Agent readiness

- Правила написаны командами.
- Нет философии и motivational prose.
- Нет vague language.
- Термины единообразны.

### Safety

- Sources ограничены.
- Writes ограничены.
- Confirmation gate определен.
- Idempotency определена.
- Нет silent migration.

### Output and validation

- Output contract стабилен.
- Stop condition определен.
- Evals покрывают реальные сценарии.
- References discoverable.
