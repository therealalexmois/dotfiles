# Neovim Python DAP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development
> (recommended) or executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** довести Python debugging в Neovim до практического 80/20-паритета с
PyCharm: сохраненные DAP-конфигурации, удобные breakpoints, debug теста под
курсором и надежный attach к debugpy socket.

**Architecture:** сохранить текущую связку AstroNvim, `nvim-dap`,
`nvim-dap-python`, `nvim-dap-ui` и Mason `debugpy`. Добавить один локальный
Python DAP-модуль и одну plugin spec без новых зависимостей. Проектные параметры
хранить в `.vscode/launch.json`, который текущий `nvim-dap` уже читает
автоматически при `dap.continue()`.

**Tech Stack:** Neovim 0.12, Lua, AstroNvim, nvim-dap, nvim-dap-python,
debugpy, plain headless Lua assertions, StyLua, Selene.

---

## Scope

Входит:

- явная проверка `debugpy-adapter` без fallback на отсутствующий `python`;
- disconnect от attach-сессии без завершения target;
- exception breakpoints, logpoints, hit-count breakpoints и список breakpoints;
- debug ближайшего pytest method и class;
- документация для file, module, local socket и remote/container attach;
- headless и ручные smoke-проверки.

Не входит:

- arbitrary PID injection на macOS;
- Smart Step Into, scientific/DataFrame viewer и PyCharm-подобный test runner;
- новая тестовая или debugger-зависимость;
- изменения проектных `.vscode/launch.json` за пределами dotfiles;
- commit, push или cleanup без отдельного разрешения.

## File Structure

- Create: `nvim/lua/config/debugging/python.lua` - проверка adapter и небольшие
  Python DAP-действия.
- Create: `nvim/lua/plugins/debugging/python-dap.lua` - локальная настройка
  `nvim-dap-python` и discoverable mappings.
- Create: `nvim/tests/python_dap_spec.lua` - dependency-free headless assertions
  для adapter preflight.
- Create: `nvim/DAP.md` - пользовательский runbook, launch-конфигурации и smoke
  matrix.

## Acceptance Criteria

- Python buffer загружает `nvim-dap-python` через Mason `debugpy-adapter`.
- Отсутствующий adapter дает одну явную ошибку и не запускает системный `python`.
- `F5` показывает встроенные и project-level конфигурации.
- Logpoint не останавливает процесс; hit-count останавливает на указанном
  проходе; exception picker предлагает фильтры adapter.
- Debug test method/class запускает pytest-конфигурацию из позиции курсора.
- Disconnect от socket attach оставляет target живым.
- Local socket attach проходит end-to-end; PID attach документирован как
  non-goal на macOS.

---

### Task 1: Зафиксировать adapter preflight тестом

**Files:**

- Create: `nvim/tests/python_dap_spec.lua`

- [ ] **Step 1: Создать dependency-free тест до production-модуля**

```lua
vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/nvim")

local python_dap = require "config.debugging.python"

local function eq(actual, expected, message)
  assert(vim.deep_equal(actual, expected), message or vim.inspect { actual = actual, expected = expected })
end

local resolved, resolve_err = python_dap.resolve_adapter(function(name)
  eq(name, "debugpy-adapter")
  return "/tmp/mason/bin/debugpy-adapter"
end)
eq(resolved, "/tmp/mason/bin/debugpy-adapter")
eq(resolve_err, nil)

local missing, missing_err = python_dap.resolve_adapter(function() return "" end)
eq(missing, nil)
assert(missing_err:find("debugpy%-adapter", 1, false))

local calls = {}
local notifications = {}
local ok = python_dap.setup({ console = "integratedTerminal" }, {
  exepath = function() return "/tmp/mason/bin/debugpy-adapter" end,
  dap_python = {
    setup = function(path, opts) table.insert(calls, { path = path, opts = opts }) end,
  },
  notify = function(message, level) table.insert(notifications, { message = message, level = level }) end,
  schedule = function(callback) callback() end,
})
eq(ok, true)
eq(calls, {
  {
    path = "/tmp/mason/bin/debugpy-adapter",
    opts = { console = "integratedTerminal" },
  },
})
eq(#notifications, 0)

local missing_ok = python_dap.setup({}, {
  exepath = function() return "" end,
  dap_python = { setup = function() error "setup must not run" end },
  notify = function(message, level) table.insert(notifications, { message = message, level = level }) end,
  schedule = function(callback) callback() end,
})
eq(missing_ok, false)
assert(notifications[#notifications].message:find("debugpy%-adapter", 1, false))

print "python_dap_spec: ok"
```

- [ ] **Step 2: Запустить тест и подтвердить ожидаемый RED**

Run:

```sh
nvim --headless -u NONE -l nvim/tests/python_dap_spec.lua
```

Expected: exit non-zero с `module 'config.debugging.python' not found`.

### Task 2: Добавить fail-fast Python DAP-модуль

**Files:**

- Create: `nvim/lua/config/debugging/python.lua`
- Test: `nvim/tests/python_dap_spec.lua`

- [ ] **Step 1: Реализовать adapter resolution и setup**

```lua
local M = {}

local ERROR_MESSAGE = "Python DAP is unavailable: Mason executable debugpy-adapter was not found. Run :MasonToolsInstall."

function M.resolve_adapter(exepath)
  local path = (exepath or vim.fn.exepath) "debugpy-adapter"
  if path == "" then return nil, ERROR_MESSAGE end
  return path, nil
end

function M.setup(opts, dependencies)
  dependencies = dependencies or {}
  local path, err = M.resolve_adapter(dependencies.exepath)

  if not path then
    local notify = dependencies.notify or vim.notify
    local schedule = dependencies.schedule or vim.schedule
    schedule(function() notify(err, vim.log.levels.ERROR, { title = "Python DAP" }) end)
    return false
  end

  local dap_python = dependencies.dap_python or require "dap-python"
  dap_python.setup(path, opts or {})
  return true
end

function M.detach()
  local dap = require "dap"
  dap.disconnect({ terminateDebuggee = false }, function() dap.close() end)
end

local function persist_current_buffer_breakpoints()
  local ok, persistence = pcall(require, "persistent-breakpoints.api")
  if ok then persistence.breakpoints_changed_in_current_buffer() end
end

function M.set_logpoint()
  vim.ui.input({ prompt = "Log point message: " }, function(message)
    message = vim.trim(message or "")
    if message == "" then return end
    require("dap").set_breakpoint(nil, nil, message)
    persist_current_buffer_breakpoints()
  end)
end

function M.set_hit_condition()
  vim.ui.input({ prompt = "Break after hit count: " }, function(count)
    count = vim.trim(count or "")
    if count == "" then return end
    require("dap").set_breakpoint(nil, count)
    persist_current_buffer_breakpoints()
  end)
end

return M
```

- [ ] **Step 2: Запустить тест и подтвердить GREEN**

Run:

```sh
nvim --headless -u NONE -l nvim/tests/python_dap_spec.lua
```

Expected: `python_dap_spec: ok`, exit 0.

- [ ] **Step 3: Отформатировать модуль и тест**

Run:

```sh
stylua nvim/lua/config/debugging/python.lua nvim/tests/python_dap_spec.lua
```

Expected: файлы переформатированы без ошибок.

### Task 3: Подключить mappings и заменить нерабочий fallback

**Files:**

- Create: `nvim/lua/plugins/debugging/python-dap.lua`

- [ ] **Step 1: Создать локальную spec для существующих плагинов**

```lua
---@type LazySpec
return {
  {
    "mfussenegger/nvim-dap-python",
    optional = true,
    config = function(_, opts) require("config.debugging.python").setup(opts) end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      local maps = opts.mappings

      maps.n["<Leader>dd"] = {
        function() require("config.debugging.python").detach() end,
        desc = "Detach Debugger",
      }
      maps.n["<Leader>dx"] = {
        function() require("dap").set_exception_breakpoints() end,
        desc = "Exception Breakpoints",
      }
      maps.n["<Leader>dl"] = {
        function() require("config.debugging.python").set_logpoint() end,
        desc = "Set Logpoint",
      }
      maps.n["<Leader>dL"] = {
        function() require("config.debugging.python").set_hit_condition() end,
        desc = "Set Hit-count Breakpoint",
      }
      maps.n["<Leader>dv"] = {
        function() require("dap").list_breakpoints() end,
        desc = "List Breakpoints",
      }
      maps.n["<Leader>dt"] = {
        function() require("dap-python").test_method() end,
        desc = "Debug Python Test Method",
      }
      maps.n["<Leader>dT"] = {
        function() require("dap-python").test_class() end,
        desc = "Debug Python Test Class",
      }
    end,
  },
}
```

- [ ] **Step 2: Проверить формат**

Run:

```sh
stylua --check nvim/lua/plugins/debugging/python-dap.lua
```

Expected: exit 0.

- [ ] **Step 3: Проверить реальную lazy-конфигурацию**

Run:

```sh
nvim --headless "+set filetype=python" "+lua assert(vim.fn.exepath('debugpy-adapter') ~= '')" "+lua assert(require('dap').adapters.python ~= nil)" "+lua assert(vim.fn.maparg('<Leader>dt', 'n') ~= '')" +qa
```

Expected: exit 0 без Lua error.

### Task 4: Написать Python DAP runbook

**Files:**

- Create: `nvim/DAP.md`

- [ ] **Step 1: Описать основной keyboard loop**

Добавить таблицу:

```markdown
| Действие | Клавиши |
| --- | --- |
| Start / continue и выбор конфигурации | `F5`, `<leader>dc` |
| Pause | `F6`, `<leader>dp` |
| Breakpoint / conditional breakpoint | `F9`, `Shift-F9` |
| Step over / into / out | `F10`, `F11`, `Shift-F11` |
| Run to cursor | `<leader>ds` |
| Evaluate / hover / REPL | `<leader>dE`, `<leader>dh`, `<leader>dR` |
| Exception / logpoint / hit count | `<leader>dx`, `<leader>dl`, `<leader>dL` |
| Breakpoint list | `<leader>dv` |
| Debug pytest method / class | `<leader>dt`, `<leader>dT` |
| Detach / terminate | `<leader>dd`, `Shift-F5` |
```

- [ ] **Step 2: Добавить project-level `.vscode/launch.json` пример**

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: current file",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "cwd": "${workspaceFolder}",
      "envFile": "${workspaceFolder}/.env",
      "justMyCode": true
    },
    {
      "name": "Python: module",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": ["app.main:app", "--reload"],
      "cwd": "${workspaceFolder}",
      "envFile": "${workspaceFolder}/.env",
      "justMyCode": true
    },
    {
      "name": "Python: attach localhost:5678",
      "type": "python",
      "request": "attach",
      "connect": { "host": "127.0.0.1", "port": 5678 },
      "justMyCode": true
    },
    {
      "name": "Python: attach container",
      "type": "python",
      "request": "attach",
      "connect": { "host": "127.0.0.1", "port": 5678 },
      "pathMappings": [
        { "localRoot": "${workspaceFolder}", "remoteRoot": "/app" }
      ],
      "justMyCode": true
    }
  ]
}
```

Зафиксировать, что `.env` остается local-only, а секреты не копируются в
dotfiles.

- [ ] **Step 3: Описать socket attach вместо PID injection**

```sh
python3 -m debugpy --listen 127.0.0.1:5678 -m uvicorn app.main:app
python3 -m debugpy --listen 127.0.0.1:5678 --wait-for-client -m uvicorn app.main:app
```

Документировать порядок: запустить приложение, открыть Python buffer, нажать
`F5`, выбрать `Python: attach localhost:5678`, поставить breakpoint, после
проверки выполнить `<leader>dd`.

- [ ] **Step 4: Явно записать ограничения**

Записать, что `debugpy --pid <PID>` на текущем macOS smoke упирается в право
получения task port. Это не fallback для socket attach и не критерий готовности
первой версии.

### Task 5: Прогнать regression и live smoke matrix

**Files:**

- Verify: `nvim/lua/config/debugging/python.lua`
- Verify: `nvim/lua/plugins/debugging/python-dap.lua`
- Verify: `nvim/tests/python_dap_spec.lua`
- Verify: `nvim/DAP.md`

- [ ] **Step 1: Запустить статические проверки**

```sh
stylua --check nvim
(cd nvim && selene .)
nvim --headless "+checkhealth" +qa
```

Expected: все команды exit 0. Любой pre-existing warning `checkhealth` записать
отдельно и не выдавать за регрессию задачи.

- [ ] **Step 2: Проверить file и module launch**

Для тестового Python-проекта проверить args, cwd, env, остановку на breakpoint,
step over, evaluate и terminate. Expected: значения доступны в DAP UI и virtual
text, процесс завершается только по terminate.

- [ ] **Step 3: Проверить local socket attach**

Запустить target через `python3 -m debugpy --listen 127.0.0.1:5678 ...`, выбрать
attach-конфигурацию, дождаться breakpoint, выполнить evaluate, затем detach.
Expected: DAP-сессия закрыта, target остается жив.

- [ ] **Step 4: Проверить breakpoint modes**

Проверить `raised` и `uncaught`, logpoint с `{variable}`, hit count `3` и список
breakpoints. Expected: logpoint пишет значение без остановки, hit-count
останавливает на третьем проходе.

- [ ] **Step 5: Проверить pytest и async/subprocess границы**

Проверить `<leader>dt` и `<leader>dT` в pytest-файле. Затем проверить breakpoint
в async frame и child process с project config `subProcess: true`. Если debugpy
не подтверждает child attach или evaluate, оставить это как известный P1 gap, а
не расширять P0.

- [ ] **Step 6: Проверить точный diff**

```sh
git diff --check -- nvim docs/plans/2026-09-06-neovim-python-dap-plan.md
git status --short
```

Expected: diff check чистый; unrelated
`ai-agents/.codex/config.shared.toml` остается неизмененным этой задачей.

- [ ] **Step 7: Commit checkpoint только при отдельном разрешении**

Если пользователь отдельно разрешил commit:

```sh
git add nvim/lua/config/debugging/python.lua \
  nvim/lua/plugins/debugging/python-dap.lua \
  nvim/tests/python_dap_spec.lua \
  nvim/DAP.md
git commit -m "feat(nvim): improve Python DAP workflows"
```

Без отдельного разрешения не выполнять `git add` и `git commit`.

---

## Self-Review

- **Coverage:** file/module launch, socket attach, detach, breakpoints, pytest,
  async/subprocess probe, documentation и regression checks покрыты отдельными
  задачами.
- **Scope:** PID injection, PyCharm scientific UI и новый test runner исключены.
- **Type consistency:** `resolve_adapter()` возвращает `path | nil, error | nil`;
  `setup()` возвращает boolean и принимает одинаковый dependency contract в
  тесте и production.
- **Проверка полноты:** в плане нет заглушек, скрытых implementation steps или
  неопределенных функций.
- **Git authority:** commit является отдельным условным checkpoint; push и merge
  отсутствуют.
