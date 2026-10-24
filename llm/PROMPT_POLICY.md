# PROMPT_POLICY

## Purpose

Правила для библиотеки prompts в Neovim:

- хранить общие prompts отдельно от проектных;
- отделять prompts от правил репозитория, настроек плагинов и секретов;
- задавать единый контракт метаданных;
- использовать одну библиотеку для `home_local` и `work_proxy`.

## Scope

| Входит в политику | Не входит в политику |
| --- | --- |
| Общие prompts: `~/.dotfiles/llm/prompts` | Настройка плагинов и keymaps |
| Проектные prompts: `<repo>/.prompts` | Backend adapters и загрузка repo-rules |

## Design principles

1. **Prompt-first UX.** AI в редакторе выполняет prompts и workflows.
2. **One prompt identity.** Один сценарий сохраняет имя при смене профиля:
   `commit`, а не `commit-home` и `commit-work`.
3. **Global first, project override when needed.** Общие сценарии хранятся глобально.
   Проектный вариант нужен только для локальных требований.
4. **Review before apply.** Изменения кода проходят через интерфейс проверки.
5. **Git-tracked prompts.** Храни prompts в Git как Markdown-файлы.

## Storage model

| Библиотека | Путь | Что хранить |
| --- | --- | --- |
| Общая | `~/.dotfiles/llm/prompts` | Повседневные сценарии, пригодные для разных проектов |
| Проектная | `<repo>/.prompts` | Тесты, рефакторинг и другие сценарии с локальными соглашениями |

## Prompt precedence

Для одного назначения:

1. Используй проектный prompt, если он существует.
2. Иначе используй общий prompt.
3. Не подменяй отсутствующий prompt другим по смыслу без уведомления.

## Prompt taxonomy

### Operational prompts

Текущая общая библиотека:

| Prompt | Файлы и выполнение |
| --- | --- |
| `commit` | `commit.md` + `commit.lua` |
| `branch-name` | `branch-name.md` |
| `branch-from-diff` | `branch-from-diff.md` + `branch.lua` |
| `explain` | `explain.md` |
| `fix` | `fix.md` |
| `lsp` | `lsp.md` + `lsp.lua` |
| `review` | `review.md`, chat |
| `refactor` | `refactor.md`, inline, `placement: replace` |
| `docstring` | `docstring.md` |
| `unit-tests` | `unit-tests.md` |
| `inline-prompt` | `inline-prompt.md` |
| `code-workflow` | `code-workflow.md`, `interaction: workflow` |

### Project prompts

Проектный prompt специализирует категорию, но не заменяет ее.
Примеры назначений:

- `tests-python-project`;
- `refactor-clean-architecture`;
- `docstring-google-style`;
- `commit-message-project-convention`.

## Prompt vs repo-rules

| Слой | Вопрос | Примеры |
| --- | --- | --- |
| Prompt | Что сделать? | Объяснить код, написать commit message, предложить имя, создать тесты |
| Repo-rule | По каким постоянным правилам? | Стиль docstrings, структура тестов, архитектурные ограничения, запрещенные приемы |

Не смешивай эти слои.

## Metadata contract

Формат CodeCompanion: YAML frontmatter и секции ролей `## system` / `## user`.
Загрузчик `codecompanion/prompt_library/markdown.lua` проверяет `name` и `interaction`.
При нехватке обязательных данных prompt игнорируется с предупреждением.

### Frontmatter fields

| Поле | Назначение |
| --- | --- |
| `name` | Имя в action palette. Всегда задавай явно. Загрузчик также может взять имя файла. |
| `description` | Краткое описание для палитры. |
| `interaction` | `chat`, `inline` или `workflow`. |
| `opts` | Параметры выполнения, перечисленные ниже. |
| `tools` | Доступные tools; `none`, если они не нужны. |
| `mcp_servers` | Доступные MCP-серверы; `none`, если они не нужны. |

Параметры `opts`:

| Параметр | Назначение |
| --- | --- |
| `alias` | Короткое имя команды и записи палитры: `commit`, `branch`, `explain`. |
| `is_slash_cmd` | Зарегистрировать `/alias`. |
| `auto_submit` | Отправить запрос без ручного редактирования. |
| `modes` | Режимы доступности, например `[v]` для visual. |
| `placement` | Куда поместить inline-ответ: `replace`, `new`, `add`, `before`, `chat`. |
| `user_prompt` | Запросить ввод: `true` или строка-подсказка. |
| `ignore_system_prompt` | Не добавлять общий system prompt адаптера. |
| `stop_context_insertion` | Не добавлять контекст буфера автоматически. |
| `is_workflow` | Пометить сценарий из нескольких ходов. |

### Body and variables

- Роли чата задаются заголовками `## system` и `## user`.
- `${context.*}` подставляет контекст CodeCompanion: `code`, `filetype`, `bufnr`,
  `start_line`, `end_line` и другие поля.
- `${ns.fn}` вызывает функцию из соседнего `ns.lua`. Namespace задает имя Lua-файла,
  а не имя `.md`. Lua-файл возвращает таблицу функций.

| Переменная | Резолвер |
| --- | --- |
| `${commit.input}` | `commit.lua` |
| `${branch.status}` | `branch.lua` |
| `${lsp.diagnostics}` | `lsp.lua` |

## Metadata example

Frontmatter из `prompts/commit.md`:

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

## Planned / not yet implemented

Эти поля были предложены ранее. Загрузчик их не использует; в текущих prompts их нет.
Добавляй поле только вместе с кодом, который его читает.

| Поле | Предложенное значение | Чем выражено сейчас |
| --- | --- | --- |
| `kind` | `ask`, `explain`, `refactor`, `tests`, `commit`, ... | Назначением prompt |
| `scope` | `global`, `project` | Расположением файла |
| `requires` | `selection`, `diff`, `staged_git`, ... | Переменными `${...}` |
| `profiles` | `home_local`, `work_proxy`, `both` | Общей библиотекой и адаптерами |
| `review_mode` | `none`, `diff`, `replace` | `interaction` и `placement` |

## Naming rules

- Имя файла: короткое, стабильное, kebab-case.
- Примеры: `commit.md`, `branch-name.md`, `branch-from-diff.md`, `docstring.md`,
  `explain.md`, `unit-tests.md`.
- Frontmatter `name`: стабильное и уникальное в библиотеке.
- Согласуй смысл `name`, имени файла и `opts.alias`.

## Authoring rules

| Создавать | Условия |
| --- | --- |
| Общий prompt | Полезен большинству проектов. Не требует локальных правил или проектного контекста. |
| Проектный prompt | Зависит от локальных требований к тестам, архитектуре или стилю. Нужен только одному репозиторию. |

Не создавай отдельный prompt из-за смены модели, backend или home/work profile.
Если различие выражается метаданными или входным контекстом, используй их.

## Execution rules

Безопасность определяется `interaction` и `opts.placement`.
Отдельного рабочего поля `review_mode` нет.

### Chat prompts (non-destructive)

`interaction: chat` пишет ответ в чат-буфер и не меняет код.
Для таких prompts допустим `auto_submit: true`:

- `commit`;
- `branch-name`, `branch-from-diff`;
- `explain`, `fix`, `lsp`, `review`.

### Inline prompts (через reviewable surface)

| Placement | Текущие prompts | Проверка и применение |
| --- | --- | --- |
| `replace` | `docstring.md`, `refactor.md` | Заменяет выделение через diff-UI с accept/reject при `display.diff.enabled`. Этот режим включен по умолчанию; требуется явный accept. |
| `new` | `unit-tests.md` | Создает новый буфер. Существующий код не меняется. |

- `docstring`: `auto_submit: true`.
- `refactor`: `auto_submit: false`, чтобы отредактировать запрос перед отправкой.

### Safety rule

- Не допускай молчаливой перезаписи кода inline-prompt.
- Для `replace` сохраняй включенным `display.diff`: применение требует accept/reject.
- `new`, `add` и `before` допустимы без diff, поскольку не уничтожают существующий код.

## Profile rules

Библиотека общая для `home_local` и `work_proxy`.
Profile выбирает:

- backend выполнения;
- требования auth/env;
- модель;
- ожидаемые задержки и возможности.

Profile не меняет логическое назначение или имя prompt.

## Current prompt pack

Текущие общие prompts перечислены в [Prompt taxonomy](#prompt-taxonomy).

Пока не реализованы:

- общие: `ask-selected`, `better-name`;
- проектные: `generate-tests`, `project-refactor`, `project-docstring`,
  `project-commit-style`.

Создавай проектные варианты только при подтвержденной необходимости.

## Review checklist for new prompt

- [ ] Сценарий отличается от существующих.
- [ ] Выбрана общая или проектная библиотека.
- [ ] Заданы `name`, `interaction` и нужные `opts`.
- [ ] Имя файла короткое, стабильное и в kebab-case.
- [ ] Inline `replace` использует diff-UI, без молчаливой записи.
- [ ] Prompt не дублирует repo-rules.
- [ ] Нет лишнего разделения на home/work.

## Non-goals

Политика не описывает:

- автозагрузку repo-rules;
- linting и аналитику prompts;
- dynamic model discovery;
- синхронизацию помимо Git;
- автоматические шаблоны prompts.

## Change policy

Обновляй `PROMPT_POLICY.md` при изменении taxonomy, контракта метаданных,
хранения, precedence или выполнения.
Текст отдельного prompt можно менять без правки политики, если ее правила сохранены.
