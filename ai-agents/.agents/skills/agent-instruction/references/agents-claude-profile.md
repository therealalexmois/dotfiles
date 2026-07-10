# AGENTS.md and CLAUDE.md Profile

## Purpose

Используй этот profile для создания и строгого review coding-agent configuration files.

Проверяй не литературное качество, а способность файла снизить вероятность ошибки агента.

## Platform facts

Поведение Claude Code, Codex и других agents меняется.

Перед утверждением о:

- locations;
- import syntax;
- precedence;
- path-scoped rules;
- hooks;
- permissions;
- supported metadata;

проверь актуальную официальную документацию.

Если web или docs недоступны, пометь утверждение как непроверенное. Не превращай исторический пример в текущий contract.

## Source of truth

Выбери один canonical source для общих project rules.

Проверь:

- platform adapter не копирует общий contract;
- scoped files содержат только scoped rules;
- одинаковые команды и architecture rules не расходятся;
- imports не используются как иллюзия экономии context без проверки platform behavior.

Не навязывай конкретную схему `AGENTS.md` + `CLAUDE.md`, если текущая платформа использует другой supported mechanism. Сначала проверь capability.

## Required content

Root coding-agent instruction обычно должен содержать только material project constraints:

- краткий project overview;
- repository layout, если его нельзя надежно вывести;
- setup/build/test/lint/typecheck commands;
- architecture boundaries;
- coding conventions, которые нельзя получить из formatter/linter;
- testing rules;
- security and safety constraints;
- verification;
- done criteria;
- explicit do-not rules.

Не копируй README, API documentation и полный onboarding guide.

## Verification first

Инструкция должна объяснять, как доказать готовность изменения.

Укажи конкретные commands или observable checks.

Плохо:

```text
Убедись, что все работает.
```

Хорошо:

```text
После изменения application layer запусти unit tests этого слоя.
После изменения public DTO запусти typecheck проекта.
Если check не запускался, укажи причину в final response.
```

Если точные команды неизвестны, не выдумывай их. Поставь `TBD` или получи их из project config.

## Context budget

Каждая строка должна снижать риск ошибки или помогать принять решение.

Удаляй:

- длинный onboarding;
- file-by-file описание repository;
- tutorial;
- очевидные language conventions;
- временные детали;
- устаревшие workflows;
- правила, которые уже enforce formatter или CI.

Оставляй:

- project-specific boundaries;
- команды, которые нельзя угадать;
- нетривиальные gotchas;
- правила, которые agent регулярно нарушает;
- verification и safety.

Не используй жесткий лимит строк как абсолютное правило. Считай большой root file сигналом для проверки progressive disclosure.

## Progressive disclosure

В root file держи только always-relevant context.

Узкий контекст вынеси в supported scoped mechanism:

- path-specific rules;
- skills;
- references;
- project documentation, которую инструкция читает по trigger.

Для каждого вынесенного source укажи, когда его читать.

## No lint leakage

Не описывай вручную то, что должен проверять formatter, linter, typechecker, pre-commit или CI.

В instruction оставь:

- какой check запустить;
- когда его запустить;
- что делать при failure.

Не превращай agent в linter через длинный список механических правил.

## Enforcement boundary

Markdown не гарантирует запрет.

Для hard requirements используй supported deterministic controls:

- permissions;
- hooks;
- sandbox;
- CI;
- validators;
- protected paths.

Считай `Never run destructive commands` недостаточным, если никаких controls нет и риск material.

## Conflicts and precedence

Проверь root, nested, local и platform-specific instructions вместе.

BLOCKER:

- разные команды для одного check;
- взаимоисключающие architecture rules;
- противоречащие write permissions;
- несовместимые test policies;
- adapters, которые переопределяют общий contract без явной причины.

Не угадывай precedence. Проверь platform docs или зафиксируй неопределенность.

## Security

Проверь наличие правил:

- не раскрывать secrets;
- не изменять credentials и production config без запроса;
- не выполнять destructive actions без confirmation и controls;
- не добавлять network calls, telemetry или dependencies молча;
- не записывать за пределами разрешенного scope.

Если проект имеет специальные security constraints, добавь их вместо общего boilerplate.

## Done criteria

Agent должен завершать задачу только когда:

- scope соответствует запросу;
- relevant checks выполнены;
- failures исправлены или явно описаны;
- skipped checks имеют причину;
- final response перечисляет changed files, checks и known risks.

Адаптируй список под проект. Не обещай checks, которых нет.

## Maintenance

Обновляй instruction, если:

- agent повторяет одну ошибку;
- review выявляет недокументированное правило;
- workflow или command изменился;
- правило устарело;
- новый text снижает риск ошибки больше, чем расходует context.

Удаляй stale и duplicate rules.

## Severity

### BLOCKER

- conflicting instructions;
- unsafe write или destructive behavior;
- отсутствует verification для material changes;
- отсутствует critical security rule;
- неверное platform behavior ведет к неправильным действиям.

### MAJOR

- context bloat;
- lint leakage;
- skill leakage;
- duplication;
- vague guidance;
- stale commands;
- missing done criteria;
- отсутствует progressive disclosure для большого файла.

### MINOR

- wording;
- порядок секций;
- локальная читаемость;
- несущественная терминология.

## Review output

Верни:

```text
Verdict
Blockers
Major issues
Minor issues
Smells found
Required changes
```

Используй verdict:

- `APPROVE`;
- `APPROVE WITH MINOR COMMENTS`;
- `REQUEST CHANGES`;
- `REJECT / REWRITE`.

Не переписывай файлы, если пользователь запросил только review.
