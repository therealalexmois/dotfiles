---
name: agent-instruction
layer: workflow
description: >
  Создает, редактирует и ревьюит постоянные инструкции для AI agents: SKILL.md,
  AGENTS.md, CLAUDE.md, SYSTEM.md, project rules и другие operational contracts.
  Используй, когда пользователь просит написать, сократить, декомпозировать,
  проверить или исправить agent instruction artifact. Не используй для обычной
  документации, разовых пользовательских prompt, code review, архитектурного
  проектирования или domain workflow, который инструкция должна только описывать.
---

# Agent Instruction

## Purpose

Создавай и улучшай постоянные инструкции для AI agents.

Инструкция готова, если agent понимает:

- когда ее применять;
- что сделать и чего не делать;
- какие sources и tools использовать;
- какие writes разрешены;
- какой fallback применить;
- какой результат вернуть;
- как проверить готовность.

## When to use

Используй skill для:

- `SKILL.md` и package skill;
- `AGENTS.md` и `CLAUDE.md`;
- `SYSTEM.md` и project rules;
- постоянных tool, artifact и workflow instructions;
- authoring, editing и review instruction artifact;
- декомпозиции перегруженной инструкции.

## When not to use

Не используй skill для:

- разового пользовательского prompt;
- обычного RFC, ADR или документации;
- анализа кода;
- проектирования domain workflow с нуля;
- запуска side effects, которые инструкция только описывает;
- общей языковой редактуры без agent behavior contract.

## Routing

Выбери один основной mode:

- `author` – создать новый artifact;
- `edit` – переписать artifact без изменения фактического поведения;
- `review` – найти проблемы без автоматического rewrite.

Если пользователь просит проверить и исправить, используй `review`, затем перепиши artifact по обязательным findings.

Выбери не более одного profile:

- `generic` – `SYSTEM.md`, project rules и другие постоянные инструкции;
- `skill` – `SKILL.md` и package skill;
- `agents-claude` – `AGENTS.md`, `CLAUDE.md` и scoped coding-agent rules.

Не загружай profiles на всякий случай.

## Inputs

Для authoring нужны:

- назначение инструкции;
- тип artifact;
- фактические правила поведения.

Для edit/review нужен текущий artifact.

Полезны:

- соседние instructions и precedence;
- available tools;
- write policy;
- типичные ошибки agent;
- verification commands;
- platform constraints;
- eval cases.

Если данных достаточно, не проводи интервью.
Если отсутствующая информация меняет behavior contract, задай один вопрос.
Если вопрос невозможен, пометь пробел и выбери безопасное минимальное поведение.

## Source policy

Разрешено использовать:

- явный ввод пользователя;
- приложенные artifacts;
- разрешенные project files;
- tool outputs текущего запуска;
- актуальную официальную документацию для platform behavior.

Запрещено:

- выдумывать tools, permissions, paths, hooks или precedence;
- считать example текущей конфигурацией;
- использовать устаревший platform behavior без проверки;
- читать unrelated sources;
- молча объединять конфликтующие правила.

## Reference loading

Всегда используй [references/instruction-contract.md](references/instruction-contract.md).

Дополнительно:

- для `SKILL.md` используй [references/skill-profile.md](references/skill-profile.md);
- для `AGENTS.md` или `CLAUDE.md` используй [references/agents-claude-profile.md](references/agents-claude-profile.md).

Не используй оба profile reference, если пользователь не просит проверить их интеграцию.

## Workflow

### 1. Определи contract

Определи:

- artifact;
- mode;
- profile;
- target agent;
- поведение, которое инструкция должна изменить;
- допустимые side effects.

Если intent не относится к agent instructions, останови workflow.

### 2. Прочитай hierarchy

Для edit/review прочитай:

- target artifact;
- parent и imported instructions;
- scoped rules, влияющие на precedence;
- references, которые artifact требует читать.

Не оценивай файл изолированно, если он зависит от hierarchy.

### 3. Построй behavior map

Выдели:

- triggers;
- actions и prohibitions;
- conditions и fallbacks;
- sources и tools;
- writes и confirmation gates;
- output contract;
- validation и stop condition.

Отметь missing и conflicting elements.

### 4. Выбери структуру

Оставь один файл, если есть один workflow без длинных domain rules.

Используй references, если есть modes, profiles, длинные contracts, templates или редко используемые details.

Раздели на skills, если различаются:

- пользовательские intents;
- write policies;
- external systems;
- confirmation gates.

Не создавай файл без отдельного сценария использования.

### 5. Напиши или исправь artifact

- Пиши правила как команды.
- Используй одно действие в одном предложении.
- Используй один термин для одного смысла.
- Пиши условия через `если`.
- Добавляй fallback к жесткому правилу.
- Добавляй check к критичному правилу.
- Удаляй текст, который не меняет behavior.
- Не заменяй deterministic enforcement текстовой просьбой.

### 6. Проверь writes и safety

Если инструкция разрешает write, укажи:

- allowed и forbidden targets;
- confirmation gate;
- duplicate check;
- conflict behavior;
- post-write validation.

Если правило должно исполняться без исключений, укажи подходящий permissions, hook, sandbox, CI или validator. Не называй Markdown гарантией enforcement.

### 7. Проверь результат

Проверь:

- один bounded context;
- понятные triggers и exclusions;
- отсутствие conflicts и duplicates;
- исполняемый workflow;
- явные sources, tools и writes;
- стабильный output contract;
- stop condition;
- отсутствие непроверенных platform claims;
- evals для non-trivial skill.

## Decision rules

- Используй modes для операций одного bounded context.
- Разделяй skills, если intent или safety gate различаются.
- Не копируй в root instruction сведения, которые надежно доступны из кода или tool config.
- Выноси редкий workflow в reference или отдельный skill.
- Проверяй изменяемые platform facts по официальной документации.
- Не возвращай rewrite, если пользователь запросил только review.

## Write policy

Разрешено:

- создавать запрошенный instruction artifact;
- изменять явно указанный artifact;
- создавать необходимые references, templates и evals.

Перед записью:

1. Прочитай target.
2. Проверь соседние instructions.
3. Сохрани unrelated content.
4. Проверь duplicates.
5. После записи перечитай результат.

Запрещено:

- менять unrelated files;
- создавать external side effects;
- удалять уникальное правило без объяснения;
- мигрировать hierarchy молча.

## Output contract

### Author или Edit в чате

Верни полный готовый artifact.
После него укажи только критичные assumptions или gaps.

### Author или Edit с записью

Верни:

1. changed files;
2. changes;
3. validation result;
4. unresolved gaps.

### Review

Верни применимые секции:

1. `Verdict`;
2. `Blockers`;
3. `Major issues`;
4. `Minor issues`;
5. `Required changes`.

Не возвращай полный rewrite без запроса.

## Validation checklist

- Выбран один mode.
- Выбран не более чем один profile.
- Artifact имеет один bounded context.
- Каждое правило меняет behavior или проверяет его.
- Conditions, fallbacks и stop condition явны.
- Sources и writes ограничены.
- Side effects защищены.
- Output contract стабилен.
- Нет duplicate source of truth.
- Scope не расширен.

## Templates

Используй templates только как каркас:

- [assets/instruction-template.md](assets/instruction-template.md);
- [assets/skill-template.md](assets/skill-template.md);
- [assets/agents-claude-template.md](assets/agents-claude-template.md).

Удаляй неприменимые секции. Не оставляй пустые заголовки.
