# Библиотека prompts

Каталог хранит общие prompts для CodeCompanion в Neovim.
Правила библиотеки описаны в [PROMPT_POLICY.md](PROMPT_POLICY.md).

## Структура и границы

| Путь | Назначение |
| --- | --- |
| `~/.dotfiles/llm/prompts/` | Общие prompts и Lua-резолверы переменных |
| `~/.dotfiles/llm/PROMPT_POLICY.md` | Формат, размещение и правила выполнения |
| `~/.dotfiles/nvim/` | Настройки плагинов и адаптеров |
| `<repo>/.prompts/` | Prompts с требованиями конкретного проекта |

Не храните здесь секреты, адреса прокси, настройки адаптеров и правила проектов.

## Найти prompt

| Задача | Файлы |
| --- | --- |
| Git | `commit`, `branch-name`, `branch-from-diff` |
| Понять и проверить код | `explain`, `lsp`, `review` |
| Изменить код | `fix`, `refactor` |
| Документация и тесты | `docstring`, `unit-tests` |
| Произвольная задача или последовательность | `inline-prompt`, `code-workflow` |

Prompts доступны в палитре CodeCompanion и через настроенные `/alias` в чате.
Клавиши и профили приведены в [справочнике AI](../nvim/AI.md).

## Формат файла

Имя файла: короткое `kebab-case`, одно назначение на файл.
Используйте формат CodeCompanion: YAML frontmatter и секции ролей.
Пример структуры:

````markdown
---
name: Explain Code
description: Explain selected code
interaction: chat
opts:
  alias: explain
  auto_submit: true
  is_slash_cmd: true
  modes:
    - v
  stop_context_insertion: true
---

## system

Explain only what the provided code supports.

## user

Explain this code:

```${context.filetype}
${context.code}
```
````

`${context.*}` подставляет контекст CodeCompanion.
`${ns.fn}` вызывает функцию из соседнего Lua-резолвера `ns.lua`.
Полный контракт смотрите в [политике](PROMPT_POLICY.md#metadata-contract).

## Выбрать место и имя

1. Для общего сценария измените или добавьте файл в `prompts/`.
2. Для требований проекта используйте его `.prompts/`.
3. Сохраняйте одно имя при смене backend: `commit`, а не `commit-home`.
4. Для одного назначения политика отдает приоритет проектному prompt.
   Не заменяйте отсутствующий prompt другим по смыслу без уведомления.

Профили `home_local` и `work_proxy` меняют выполнение, а не имя prompt.
Подключение проектной библиотеки проверяйте в настройках конкретного проекта.

## Обновить документацию

| Изменение | Что обновить |
| --- | --- |
| Назначение каталогов или связь с Neovim | Этот README |
| Формат, приоритет или правила выполнения | `PROMPT_POLICY.md` |
| Текст отдельного сценария | Соответствующий файл в `prompts/` |

`ask-selected`, `better-name` и проектный `generate-tests` пока не входят
в текущую общую библиотеку.
