# PROMPT_POLICY

## Purpose

Этот документ фиксирует правила для prompt system в Neovim AI architecture.

Цели:
- держать prompts управляемыми и предсказуемыми;
- разделять global и project-specific prompts;
- не смешивать prompts, repo-rules и plugin config;
- задавать единый контракт для prompt metadata;
- поддерживать один prompt layer для `home_local` и `work_proxy`.

---

## Scope

Эта политика применяется к:
- global prompts в `~/.dotfiles/llm/prompts`
- project prompts в `<repo>/.prompts`

Эта политика **не** описывает:
- plugin setup
- keymaps
- backend adapters
- repo-rules implementation

---

## Design principles

1. **Prompt-first UX**  
   AI в редакторе рассматривается как слой prompts/workflows, а не просто как чат.

2. **One prompt identity**  
   Один и тот же сценарий должен иметь одну логическую identity независимо от profile.  
   Пример: `commit` остаётся `commit`, а не превращается в `commit-home` и `commit-work`.

3. **Global first, project override when needed**  
   Общие сценарии живут в global library.  
   Project prompt создаётся только если он реально зависит от конкретного репозитория.

4. **Review before apply**  
   Всё, что меняет код, должно идти через reviewable surface.

5. **Git-tracked prompts**  
   Prompts должны жить в git и быть читаемыми как обычные markdown-файлы.

---

## Storage model

### Global prompts
Хранятся в:

```text
~/.dotfiles/llm/prompts
```

Назначение:
- reusable daily workflows
- prompts общего назначения
- stable prompt pack для всех проектов

### Project prompts
Хранятся в:

```text
<repo>/.prompts
```

Назначение:
- project-specific test prompts
- project-specific refactor prompts
- prompts, завязанные на локальные соглашения проекта

---

## Prompt precedence

Если существует и global, и project prompt для одного и того же logical purpose:

1. используется **project prompt**
2. если project prompt отсутствует — используется **global prompt**
3. prompt не должен silently fallback на другой semantic prompt

---

## Prompt taxonomy

### Operational prompts
Стабильные повседневные сценарии, которые сейчас реально есть в `prompts/`:

- `commit` (`commit.md` + `commit.lua`)
- `branch-name` (`branch-name.md`)
- `branch-from-diff` (`branch-from-diff.md` + `branch.lua`)
- `explain` (`explain.md`)
- `fix` (`fix.md`)
- `lsp` (`lsp.md` + `lsp.lua`)
- `docstring` (`docstring.md`)
- `unit-tests` (`unit-tests.md`)
- `inline-prompt` (`inline-prompt.md`)
- `code-workflow` (`code-workflow.md`, `interaction: workflow`)

### Project prompts
Специализации под конкретный репозиторий:

- `tests-python-project`
- `refactor-clean-architecture`
- `docstring-google-style`
- `commit-message-project-convention`

Project prompt не заменяет category, а специализирует её.

---

## Prompt vs repo-rules

### Prompt
Prompt — это действие.

Примеры:
- explain this code
- generate commit message
- suggest better variable name
- generate tests

### Repo-rule
Repo-rule — это постоянный контекст проекта.

Примеры:
- preferred docstring style
- preferred test structure
- architecture constraints
- anti-patterns to avoid

### Rule
Prompts и repo-rules нельзя смешивать в один слой.

- prompt отвечает на вопрос **"что сделать?"**
- repo-rule отвечает на вопрос **"по каким постоянным правилам это делать?"**

---

## Metadata contract

Каждый prompt — это markdown-файл нативного формата CodeCompanion: YAML frontmatter +
тело с ролями `## system` / `## user`. Загрузчик
`codecompanion/prompt_library/markdown.lua` читает frontmatter и требует как минимум
`name` и `interaction` (иначе prompt игнорируется с предупреждением).

### Frontmatter fields

- `name` — отображаемое имя в action palette; единственное обязательное поле идентификации.
  Если не задано, CodeCompanion берёт имя файла, но мы всегда задаём `name` явно
- `description` — короткое описание; видно в палитре и помогает понять назначение
- `interaction` — UX-поверхность выполнения: `chat | inline | workflow`
- `opts` — поведение prompt’а:
  - `alias` — короткое имя для slash-команды и палитры (`commit`, `branch`, `explain`)
  - `is_slash_cmd` — регистрировать ли как `/alias` slash-команду
  - `auto_submit` — отправлять ли запрос сразу, без ручного редактирования
  - `modes` — режимы, в которых prompt доступен, например `[v]` (visual)
  - `placement` — для `inline`: куда писать ответ (`replace | new | add | before | chat`)
  - `user_prompt` — запросить ввод у пользователя (`true`) или строка-подсказка
  - `ignore_system_prompt` — не подмешивать глобальный system prompt адаптера
  - `stop_context_insertion` — не автодобавлять контекст буфера
  - `is_workflow` — пометить prompt как multi-turn workflow
- `tools` — доступные tools (`none`, если не нужны)
- `mcp_servers` — доступные MCP-серверы (`none`, если не нужны)

### Body and variables

- Тело состоит из секций `## system` и `## user` (роли чата CodeCompanion).
- Переменные `${...}` подставляются при выполнении:
  - `${context.*}` — встроенный контекст CodeCompanion (`code`, `filetype`, `bufnr`,
    `start_line`, `end_line` и т.д.)
  - `${ns.fn}` — значение из соседнего резолвера `ns.lua` (по namespace, не по имени
    `.md`). Файл `ns.lua` возвращает таблицу функций; например `${commit.input}` →
    `commit.lua`, `${branch.status}` → `branch.lua`, `${lsp.diagnostics}` → `lsp.lua`.

---

## Metadata example

Реальный frontmatter из `prompts/commit.md`:

```yaml
---
name: Commit Message
interaction: chat
description: Generate a Conventional Commit message from selected diff or staged git changes
opts:
  alias: commit
  auto_submit: true
  is_slash_cmd: true
  ignore_system_prompt: true
  stop_context_insertion: true
tools: none
mcp_servers: none
---
```

---

## Planned / not yet implemented

Поля ниже описывались в ранних версиях этой политики, но **не используются**
загрузчиком CodeCompanion и отсутствуют в реальных промптах. Оставлены как ориентир на
будущее; вводить их в frontmatter имеет смысл только вместе с кодом, который их читает.

- `kind` — тип сценария (`ask | explain | refactor | tests | commit | ...`) для классификации
- `scope` — `global | project` для разделения общих и проектных промптов
- `requires` — требуемый входной контекст (`selection | diff | staged_git | ...`) для валидации
- `profiles` — допустимые профили (`home_local | work_proxy | both`)
- `review_mode` — режим review результата (`none | diff | replace`)

Сейчас эти аспекты выражаются иначе: `scope` — расположением файла (global vs `<repo>/.prompts`),
входной контекст — переменными `${...}`, профиль-независимость — самим устройством адаптеров,
а review — поведением `interaction`/`placement` (см. Execution rules).

---

## Naming rules

### File names
Использовать короткие, предсказуемые имена в kebab-case.

Примеры (реальные файлы):
- `commit.md`
- `branch-name.md`
- `branch-from-diff.md`
- `docstring.md`
- `explain.md`
- `unit-tests.md`

### Prompt names
Frontmatter `name` (отображаемое имя в палитре) должен:
- быть стабильным
- быть уникальным в пределах библиотеки
- совпадать по смыслу с файлом и с `opts.alias`

---

## Authoring rules

### Global prompt создавать, если
- сценарий полезен в большинстве проектов
- prompt не зависит от локальных правил конкретного репозитория
- prompt можно переиспользовать без project context

### Project prompt создавать, если
- сценарий зависит от тестовых/архитектурных/стилистических требований проекта
- есть локальные ограничения, которые нельзя зашивать в global prompt
- prompt имеет смысл только внутри одного репозитория

### Не создавать отдельный prompt, если
- различие только в модели или backend
- различие только в home/work profile
- различие можно решить metadata или входным контекстом

---

## Execution rules

Безопасность определяется связкой `interaction` + `opts.placement`, а не отдельным полем
`review_mode`.

### Chat prompts (non-destructive)
`interaction: chat` пишет ответ в chat-буфер и ничего не меняет в коде. Здесь `auto_submit: true`
безопасен:

- `commit` (`commit.md`)
- `branch-name`, `branch-from-diff`
- `explain`
- `fix`
- `lsp`

### Inline prompts (через reviewable surface)
`interaction: inline` управляется `opts.placement`:

- `placement: replace` (`docstring.md`) перезаписывает выделение, но при
  `display.diff.enabled` (включено по умолчанию) CodeCompanion открывает diff-UI с
  accept/reject. Diff-UI и есть reviewable surface, поэтому `auto_submit: true` не нарушает
  safety rule: применение требует явного accept.
- `placement: new` (`unit-tests.md`) пишет результат в новый буфер и не трогает
  существующий код — неразрушающе по построению.

### Safety rule
Inline-prompt не должен молча перезаписывать существующий код. Для destructive placement
(`replace`) полагаемся на diff-UI CodeCompanion (accept/reject); отключать `display.diff`
для таких промптов нельзя. Additive placement (`new`, `add`, `before`) допустим без diff,
так как не уничтожает существующий код.

---

## Profile rules

### Shared prompt library
Prompt library общая для `home_local` и `work_proxy`.

### Profile responsibility
Profile влияет на:
- backend execution
- auth/env requirements
- model selection
- latency/capability expectations

Profile **не влияет** на logical identity prompt’а.

---

## Current prompt pack

### Global (реально существуют)
- `commit`
- `branch-name`
- `branch-from-diff`
- `explain`
- `fix`
- `lsp`
- `docstring`
- `unit-tests`
- `inline-prompt`
- `code-workflow`

### Planned (пока нет)
- `ask-selected`
- `refactor-selection`
- `better-name`

### Project (пока нет, создавать только при реальной необходимости)
- `generate-tests`
- `project-refactor`
- `project-docstring`
- `project-commit-style`

---

## Review checklist for new prompt

Перед добавлением нового prompt проверь:

- это новый сценарий, а не вариант существующего
- prompt действительно нужен как global или как project
- frontmatter заполнен: есть `name` и `interaction`, при необходимости `opts`
- имя файла короткое, стабильное, в kebab-case
- destructive inline-prompt использует `placement: replace` поверх diff-UI, а не молчаливую запись
- prompt не дублирует repo-rules
- prompt не split’ится на home/work без необходимости

---

## Non-goals

Этот документ сейчас не покрывает:
- repo-rules autoload
- prompt linting
- prompt analytics
- dynamic model discovery
- shared sync beyond git
- automatic prompt templating

---

## Change policy

Изменения в `PROMPT_POLICY.md` делать только когда меняется:
- taxonomy
- metadata contract
- storage model
- precedence rules
- execution rules

Тексты конкретных prompts менять без обновления policy можно, если они не нарушают этот документ.
