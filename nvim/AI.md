# AI в Neovim — памятка

Две независимые поверхности работают рядом:

- **CodeCompanion** (`<leader>A`) — мультимодельные операции с кодом: чат, inline-правки,
  библиотека промптов. Адаптеры переключаются: локальный Ollama, рабочий HTTP-прокси и
  Claude по ACP на подписке.
- **claudecode.nvim** (`<leader>C`) — `claude` CLI по официальному IDE-протоколу для
  агентной и research-работы с нативными diff (accept/reject). Наследует MCP-серверы,
  сабагентов, skills и rules из CLI — в Neovim настраивать нечего.

---

## Профили и выбор модели

`NVIM_AI_PROFILE` задаёт адаптер CodeCompanion по умолчанию:

| Значение | Чат по умолчанию | Inline / cmd |
| --- | --- | --- |
| `home` (по умолчанию) | Ollama (локально) | Ollama (локально) |
| `work` | work-прокси (HTTP) | work-прокси (HTTP) |
| `claude` | `claude_code` (ACP) | Ollama / work-прокси |

- Inline-правки всегда идут на HTTP-адаптеры; на ACP уходит только чат и только в профиле
  `claude`.
- `:AIProfileStatus` — показать активный профиль и результат preflight-проверки.
- Профиль меняется через env и применяется при старте: `NVIM_AI_PROFILE=claude nvim`.
- Claude-чат доступен из любого профиля по `<leader>Al`.
- Модель в `claudecode.nvim` — `<leader>Cm`.

---

## Keymaps

### CodeCompanion (`<leader>A`)

| Клавиши | Действие |
| --- | --- |
| `<leader>AA` | Палитра действий |
| `<leader>Ac` | Тоггл чата |
| `<leader>Aq` | Добавить выделение в чат (visual) |
| `<leader>Al` | Claude-чат по ACP |

### claudecode.nvim (`<leader>C`)

| Клавиши | Действие |
| --- | --- |
| `<leader>Cc` | Тоггл Claude Code |
| `<leader>Cf` | Фокус на окне Claude |
| `<leader>Cr` | Возобновить сессию (`--resume`) |
| `<leader>CC` | Продолжить последнюю сессию (`--continue`) |
| `<leader>Cb` | Добавить текущий буфер в контекст |
| `<leader>Cs` | Отправить выделение (visual) |
| `<leader>Ca` | Принять предложенный diff |
| `<leader>Cd` | Отклонить предложенный diff |
| `<leader>Cm` | Выбрать модель |
| `<leader>CR` | Research-отчёт (`:ClaudeResearch`) |
| `<leader>CS` | Статус |

---

## Промпты (библиотека `llm/prompts/`)

Грузятся в палитру действий CodeCompanion и как `/alias` slash-команды в чате. Основные
для кода:

| Команда | Назначение | Тип |
| --- | --- | --- |
| `/explain` | Объяснить выделенный код | chat |
| `/fix` | Исправить код | chat |
| `/lsp` | Объяснить LSP-диагностику | chat |
| `/review` | Ревью на баги/безопасность/перформанс (HIGH/MED/LOW) | chat |
| `/refactor` | Упростить код без смены поведения | inline (diff) |
| `/tests` | Сгенерировать unit-тесты | inline (новый буфер) |
| `/commit` | Сообщение коммита из staged-изменений | chat |

Контракт и полный список — `llm/PROMPT_POLICY.md` и `llm/README.md`.

---

## Research-флоу

`<leader>CR` (или `:ClaudeResearch <тема>`) формирует инструкцию research-агенту, копирует
её в буфер обмена и открывает Claude. Вставить инструкцию в окно Claude — агент
исследует вопрос и пишет структурированный отчёт в `docs/research/<slug>.md`.

---

## Сабагенты

Лежат в `ai-agents/.claude/agents/` (трекаются), линкуются в `~/.claude/agents` через Stow.
Видны `claude` CLI и `claudecode.nvim` (`/agents`, Task tool):

- `research-report` — исследует вопрос и пишет отчёт в файл.
- `risk-reviewer` — read-only ревью на риски (баги, безопасность, перформанс,
  поддерживаемость).

Новый сабагент: добавить `ai-agents/.claude/agents/<name>.md` (frontmatter `name`,
`description`, `tools`, `model`) и прогнать `scripts/install-ai-cli-dotfiles.sh`.

---

## Разовая настройка

1. `claudecode.nvim` работает сразу, как только установлен и залогинен `claude` CLI.
2. Claude-профиль CodeCompanion требует мост ACP:
   `npm install -g @zed-industries/claude-code-acp`.
3. Опционально, для бесшовной ACP-авторизации: `claude setup-token`, затем экспорт
   `CLAUDE_CODE_OAUTH_TOKEN` из локального shell env. Без него ACP тоже работает на
   интерактивной подписке.
4. После правок плагинов: `:Lazy sync`, перезапуск nvim, `:checkhealth`.

---

## Куда обратить внимание

- **Подписка, не API-ключ.** Обе поверхности используют подписку Claude. `ANTHROPIC_API_KEY`
  не нужен.
- **`CLAUDE_CODE_OAUTH_TOKEN` — секрет.** Только в локальном shell env, никогда не
  коммитить.
- **ACP только для чата.** В профиле `claude` inline/cmd-правки остаются на Ollama/work-прокси.
  Правки от Claude применяются через diff claudecode.nvim: `<leader>Ca` / `<leader>Cd`.
- **Имя бинаря моста.** Адаптер по умолчанию ищет `claude-agent-acp`, но в конфиге
  переопределено на реальный `claude-code-acp` (см. `codecompanion.lua`).
- **Коллизии клавиш.** `<leader>C` (uppercase) — Claude Code; `<leader>c` (lowercase) —
  закрытие буфера, занят. `<leader>A` — CodeCompanion.
- **Линт перед коммитом.** `stylua --check nvim` и `(cd nvim && selene .)` ставятся через
  Mason, глобально их может не быть. selene запускать из `nvim/`.
- **`code-workflow.md`** остаётся в библиотеке; если не используется — кандидат на удаление.

---

## Файлы

- `nvim/lua/plugins/ai/claudecode.lua` — спека claudecode.nvim, keymaps, `:ClaudeResearch`.
- `nvim/lua/plugins/ai/codecompanion.lua` — адаптеры (acp/http) и keymaps CodeCompanion.
- `nvim/lua/config/ai/codecompanion_profiles.lua` — выбор профиля, preflight, `:AIProfileStatus`.
- `llm/prompts/` — библиотека промптов; `llm/PROMPT_POLICY.md` — контракт.
- `ai-agents/.claude/agents/` — сабагенты Claude Code.
