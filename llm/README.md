# LLM

Эта папка хранит глобальные материалы для AI workflow в редакторе.

## Purpose

Здесь лежит всё, что относится к reusable prompt layer:

- global prompts
- prompt policy
- документация по prompt system

Эта папка **не** хранит:
- Neovim plugin config
- secrets
- backend credentials
- project-specific prompts

---

## Structure

```text
llm/
├── README.md
├── PROMPT_POLICY.md
└── prompts/
```

### `README.md`
Краткое описание папки и её назначения.

### `PROMPT_POLICY.md`
Source of truth для правил prompt system:
- taxonomy
- metadata contract
- storage rules
- precedence rules
- execution rules

### `prompts/`
Глобальная библиотека prompts, переиспользуемая между проектами.

---

## Relationship with Neovim config

Neovim config использует prompts из этой папки как **global prompt library**.

Ожидаемая связка:
- `~/.dotfiles/nvim` — plugin config и integration logic
- `~/.dotfiles/llm/prompts` — reusable prompts
- `<repo>/.prompts` — project-specific prompts

То есть prompt layer живёт рядом с `nvim`, но отдельно от него.

---

## Prompt locations

### Global prompts
Путь:

```text
~/.dotfiles/llm/prompts
```

Использовать для:
- `commit-message`
- `branch-name`
- `docstring`
- `ask-selected`
- `explain-code`
- `refactor-selection`
- `better-name`

### Project prompts
Путь:

```text
<repo>/.prompts
```

Использовать для:
- `generate-tests`
- prompts, завязанных на локальные coding rules
- prompts, завязанных на требования конкретного репозитория

---

## Resolution rule

Если есть и global, и project prompt для одного logical purpose:

1. использовать project prompt
2. если project prompt отсутствует — использовать global prompt
3. не делать silent fallback на другой semantic prompt

---

## Profiles

Система prompts общая для двух профилей:

- `home_local`
- `work_proxy`

### Important rule
Profile влияет на backend execution, но не на identity prompt’а.

Правильно:
- один `commit-message` prompt
- разные backend/profile execution paths

Неправильно:
- `commit-message-home`
- `commit-message-work`

---

## Prompt format

Prompts хранятся как markdown-файлы с metadata/frontmatter.

Пример:

```yaml
---
name: explain-code
description: Explain selected code in a concise and practical way
kind: explain
scope: global
interaction: chat
requires:
  - selection
profiles:
  - both
review_mode: none
---
```

```md
Explain the selected code:
- describe what it does
- mention hidden assumptions
- point out risks and edge cases
- keep the explanation concise
```

Полный contract и правила описаны в `PROMPT_POLICY.md`.

---

## Naming convention

Использовать:
- kebab-case
- короткие и стабильные имена
- одно имя на один logical purpose

Примеры:
- `commit-message.md`
- `branch-name.md`
- `docstring.md`
- `explain-code.md`
- `refactor-selection.md`

---

## What belongs here

Сюда стоит класть:
- reusable prompts
- prompts общего назначения
- prompts, которые нужны в нескольких проектах
- policy-документы

---

## What does not belong here

Сюда не стоит класть:
- project-specific prompts
- repo-rules конкретного проекта
- API keys
- proxy URLs
- model-specific secrets
- plugin-specific Lua config

---

## First-iteration prompt pack

План для первой итерации:

- `ask-selected`
- `explain-code`
- `refactor-selection`
- `commit-message`
- `branch-name`
- `docstring`
- `better-name`

Project-specific:
- `generate-tests`

---

## Change policy

### Update `README.md`, if
- изменилась структура папки
- изменилось назначение каталогов
- изменилась role separation между `nvim`, `llm`, и project `.prompts`

### Update `PROMPT_POLICY.md`, if
- изменилась taxonomy
- изменился metadata contract
- изменились precedence / execution rules

### Update files in `prompts/`, if
- меняется wording конкретного workflow
- улучшается output quality prompt’а
- уточняется reusable behavior prompt’а

---

## Notes

- Prompt system должен оставаться маленьким и управляемым.
- Не нужно плодить prompts только из-за смены backend/profile.
- Сначала добавлять global prompt, project prompt — только при реальной необходимости.
``` ````
