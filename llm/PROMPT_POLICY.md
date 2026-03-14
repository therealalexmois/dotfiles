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
   Пример: `commit-message` остаётся `commit-message`, а не превращается в `commit-home` и `commit-work`.

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
Стабильные повседневные сценарии:

- `ask`
- `explain`
- `refactor`
- `tests`
- `commit-message`
- `branch-name`
- `docstring`
- `better-name`

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

Каждый prompt должен содержать metadata contract.

### Minimal fields

- `name` — уникальное имя prompt’а; нужно для идентификации и выбора в prompt picker
- `description` — короткое описание назначения prompt’а; нужно для понимания, когда его использовать
- `kind` — тип сценария (`ask`, `explain`, `refactor` и т.д.); нужен для классификации prompt’ов
- `scope` — область действия (`global` или `project`); нужна для разделения общих и проектных prompt’ов
- `interaction` — способ взаимодействия (`chat`, `inline`, `prompt`); нужен для выбора UX-поверхности выполнения
- `requires` — какой входной контекст нужен (`selection`, `diff`, `file` и т.д.); нужен для валидации, можно ли запускать prompt в текущем состоянии
- `profiles` — в каких профилях prompt допустим (`home_local`, `work_proxy`, `both`); нужно для контроля совместимости с backend/profile
- `review_mode` — нужен ли review результата перед применением (`none`, `diff`, `replace`); нужен для безопасного выполнения destructive-сценариев

### Suggested values

- `kind`: `ask | explain | refactor | tests | commit | branch | docstring | naming`
- `scope`: `global | project`
- `interaction`: `chat | inline | prompt`
- `requires`: `selection | file | diff | staged_git | text_input`
- `profiles`: `home_local | work_proxy | both`
- `review_mode`: `none | diff | replace`

---

## Metadata example

```yaml
---
name: commit-message
description: Generate a concise commit message from staged git diff
kind: commit
scope: global
interaction: prompt
requires:
  - staged_git
profiles:
  - both
review_mode: none
---
```

---

## Naming rules

### File names
Использовать короткие, предсказуемые имена в kebab-case.

Примеры:
- `commit-message.md`
- `branch-name.md`
- `docstring.md`
- `explain-code.md`
- `refactor-selection.md`
- `generate-tests.md`

### Prompt names
`name` должен:
- быть стабильным
- быть уникальным в пределах библиотеки
- совпадать по смыслу с файлом

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

### Non-destructive prompts
Могут возвращать результат без review:

- `ask`
- `explain`
- `commit-message`
- `branch-name`
- `better-name`

### Review-required prompts
Должны возвращать результат только через reviewable surface:

- `refactor`
- `tests`
- `docstring` / `comments`, если это insertion/replacement

### Safety rule
Ничего, что меняет код, не должно применяться автоматически по умолчанию.

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

## First-iteration prompt pack

### Global
- `ask-selected`
- `explain-code`
- `refactor-selection`
- `commit-message`
- `branch-name`
- `docstring`
- `better-name`

### Project
- `generate-tests`
- `project-refactor`
- `project-docstring`
- `project-commit-style` — только если это реально нужно

---

## Review checklist for new prompt

Перед добавлением нового prompt проверь:

- это новый сценарий, а не вариант существующего
- prompt действительно нужен как `global` или как `project`
- metadata заполнена полностью
- имя короткое и стабильное
- destructive output помечен правильным `review_mode`
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
