# Neovim Headless AI Jobs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development
> (recommended) or executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** запускать Codex и Claude как фоновые задачи из Neovim, продолжать
редактирование в основном checkout и открывать статус или результат без
превращения Neovim в agent harness.

**Architecture:** Neovim владеет только dispatch, локальным job registry,
status/open/cancel UI и scratch-буферами. Перед каждым запуском он создает
отдельный worktree через существующий canonical wrapper. Codex работает как
асинхронный `codex exec`, Claude делегирует lifecycle нативному `claude --bg`;
никакие изменения не выполняются в основном checkout.

**Tech Stack:** Neovim 0.12 `vim.system()`, Lua, AstroNvim/astrocore,
Codex CLI 0.153+, Claude Code 2.1+, canonical `git-worktree` wrapper, plain
headless Lua assertions, StyLua, Selene.

---

## Scope

Входит:

- `read` и `write` режимы для Codex и Claude;
- новый worktree для каждого запуска, всегда от зафиксированного Git-состояния;
- команды start/list/open/cancel и четыре mappings;
- process-level status без semantic reasoning parser;
- Codex output в scratch buffer и Claude logs через нативный CLI;
- явная политика без commit, push, PR, merge и обхода permissions;
- unit-like headless tests с fake process adapter и один controlled live smoke
  на провайдера.

Не входит:

- сохранение общего job registry после перезапуска Neovim;
- очередь, retries, scheduling, subagents или dependency graph;
- автоматический cleanup worktree или ветки;
- автоматическое применение diff, commit, push или PR;
- чтение незакоммиченных изменений основного checkout;
- замена CodeCompanion или интерактивного claudecode.nvim;
- новый Neovim plugin.

## Lifecycle Contract

1. `:AIJobStart` получает provider, mode и короткий prompt.
2. Определяется Git root текущего buffer/cwd.
3. Генерируется непрозрачное имя `ai/<provider>-<timestamp>-<counter>` без
   фрагментов prompt.
4. Canonical wrapper создает worktree под `stdpath("state")/ai-jobs/worktrees/`.
5. Provider стартует с `cwd`, равным новой worktree.
6. Neovim показывает `creating_worktree`, `starting`, `running`, `blocked`,
   `succeeded`, `failed` или `canceled`.
7. Результат открывается только для чтения; работа остается в worktree для
   отдельного review и cleanup.

Codex job живет не дольше текущего Neovim process. Claude job продолжает жить
под нативным supervisor после закрытия Neovim и доступен через `claude agents`.

## File Structure

- Create: `nvim/lua/config/ai/headless_providers.lua` - provider argv,
  safety prompt и парсинг machine-readable ответов.
- Create: `nvim/lua/config/ai/headless_runner.lua` - worktree creation,
  in-memory registry и process lifecycle.
- Create: `nvim/lua/config/ai/headless_jobs.lua` - user commands, picker,
  notifications и scratch buffers.
- Create: `nvim/lua/plugins/ai/headless-jobs.lua` - mappings через astrocore.
- Create: `nvim/tests/headless_providers_spec.lua` - provider contracts.
- Create: `nvim/tests/headless_runner_spec.lua` - state transitions и
  isolation checks с fake `vim.system`.
- Modify: `nvim/AI.md` - сценарии, команды, безопасность и ограничения.

## Acceptance Criteria

- Каждый job до запуска provider получает отдельный зарегистрированный Git
  worktree; основной checkout никогда не передается provider как `cwd`.
- Prompt не используется в branch name и для Codex передается через stdin.
- Codex read использует read-only sandbox; write использует workspace-write в
  отдельной worktree с отключенной сетью.
- Claude read использует plan mode; write использует auto mode внутри уже
  созданной worktree, поэтому commit требует отдельного внимания пользователя.
- Нет `danger-full-access`, bypass permissions, commit, push, PR или cleanup.
- Несколько jobs не блокируют Neovim и получают независимые ids/worktrees.
- Claude status `working|blocked|done|failed|stopped` отображается через
  `claude agents --json`; Codex status берется из локального process callback.
- Cancel вызывает `claude stop <id>` или `SystemObj:kill("sigterm")`.

---

### Task 1: Зафиксировать provider contracts тестами

**Files:**

- Create: `nvim/tests/headless_providers_spec.lua`

- [ ] **Step 1: Создать dependency-free test script**

```lua
vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/nvim")

local providers = require "config.ai.headless_providers"

local function eq(actual, expected, message)
  assert(vim.deep_equal(actual, expected), message or vim.inspect { actual = actual, expected = expected })
end

local worktree = providers.worktree_command {
  wrapper = "/runtime/create-worktree",
  repo = "/repo",
  path = "/state/ai-jobs/worktrees/repo/codex-20260906-120000-1",
  name = "ai/codex-20260906-120000-1",
}
eq(worktree, {
  "/runtime/create-worktree",
  "--name",
  "ai/codex-20260906-120000-1",
  "--cwd",
  "/repo",
  "--path",
  "/state/ai-jobs/worktrees/repo/codex-20260906-120000-1",
  "--format",
  "json",
})

local parsed = providers.parse_worktree_json(
  [[{"format_version":1,"repository":"/repo","worktree":"/wt","branch":"ai/codex-1","base_ref":"origin/main"}]]
)
eq(parsed.worktree, "/wt")
eq(parsed.branch, "ai/codex-1")

local codex = providers.codex {
  mode = "write",
  cwd = "/wt",
  prompt = "Compare both implementations",
}
eq(codex.cmd[1], "codex")
eq(codex.cmd[2], "-a")
eq(codex.cmd[3], "never")
assert(vim.tbl_contains(codex.cmd, "workspace-write"))
assert(vim.tbl_contains(codex.cmd, "sandbox_workspace_write.network_access=false"))
eq(codex.cmd[#codex.cmd], "-")
assert(codex.stdin:find("Do not commit", 1, true))
assert(codex.stdin:find("Compare both implementations", 1, true))

local claude = providers.claude {
  mode = "read",
  cwd = "/wt",
  name = "claude-20260906-120000-1",
  prompt = "Brainstorm alternatives",
}
eq(claude.cmd[1], "claude")
assert(vim.tbl_contains(claude.cmd, "--bg"))
assert(vim.tbl_contains(claude.cmd, "plan"))
assert(not vim.tbl_contains(claude.cmd, "--dangerously-skip-permissions"))
assert(claude.cmd[#claude.cmd]:find("Do not modify files", 1, true))

eq(providers.parse_claude_id("backgrounded · 7c5dcf5d · example\n"), "7c5dcf5d")

print "headless_providers_spec: ok"
```

- [ ] **Step 2: Запустить тест и подтвердить ожидаемый RED**

```sh
nvim --headless -u NONE -l nvim/tests/headless_providers_spec.lua
```

Expected: exit non-zero с `module 'config.ai.headless_providers' not found`.

### Task 2: Реализовать provider command builder

**Files:**

- Create: `nvim/lua/config/ai/headless_providers.lua`
- Test: `nvim/tests/headless_providers_spec.lua`

- [ ] **Step 1: Реализовать safety prompt и worktree JSON contract**

```lua
local M = {}

local BASE_POLICY = [[
You are running as a background job in an isolated Git worktree.
Work only inside the current worktree.
Do not commit, push, open or merge pull requests, or modify another checkout.
Run only checks relevant to the requested task and report changed files and unresolved risks.
]]

local function instruction(mode, prompt)
  local mode_policy = mode == "read" and "Do not modify files. Return an analysis report."
    or "Changes are allowed only inside the current worktree. Leave them uncommitted for review."
  return table.concat({ BASE_POLICY, mode_policy, "", prompt }, "\n")
end

function M.worktree_command(opts)
  return {
    opts.wrapper,
    "--name",
    opts.name,
    "--cwd",
    opts.repo,
    "--path",
    opts.path,
    "--format",
    "json",
  }
end

function M.parse_worktree_json(stdout)
  local ok, value = pcall(vim.json.decode, stdout or "")
  if not ok or type(value) ~= "table" or value.format_version ~= 1 then
    return nil, "Worktree helper returned an unsupported response"
  end
  if type(value.worktree) ~= "string" or type(value.branch) ~= "string" then
    return nil, "Worktree helper response misses worktree or branch"
  end
  return value, nil
end
```

- [ ] **Step 2: Реализовать Codex и Claude argv без shell**

```lua
function M.codex(opts)
  local sandbox = opts.mode == "read" and "read-only" or "workspace-write"
  return {
    cmd = {
      "codex",
      "-a",
      "never",
      "exec",
      "--ephemeral",
      "--color",
      "never",
      "-c",
      "sandbox_workspace_write.network_access=false",
      "-s",
      sandbox,
      "-C",
      opts.cwd,
      "-",
    },
    cwd = opts.cwd,
    stdin = instruction(opts.mode, opts.prompt),
  }
end

function M.claude(opts)
  local permission_mode = opts.mode == "read" and "plan" or "auto"
  return {
    cmd = {
      "claude",
      "--bg",
      "--name",
      opts.name,
      "--permission-mode",
      permission_mode,
      instruction(opts.mode, opts.prompt),
    },
    cwd = opts.cwd,
  }
end

function M.parse_claude_id(stdout)
  return (stdout or ""):match "backgrounded%s+·%s+([%w-]+)"
end

return M
```

- [ ] **Step 3: Запустить тест и подтвердить GREEN**

```sh
nvim --headless -u NONE -l nvim/tests/headless_providers_spec.lua
```

Expected: `headless_providers_spec: ok`, exit 0.

- [ ] **Step 4: Отформатировать и проверить provider module**

```sh
stylua nvim/lua/config/ai/headless_providers.lua nvim/tests/headless_providers_spec.lua
stylua --check nvim/lua/config/ai/headless_providers.lua nvim/tests/headless_providers_spec.lua
```

Expected: exit 0.

### Task 3: Зафиксировать runner lifecycle тестом

**Files:**

- Create: `nvim/tests/headless_runner_spec.lua`

- [ ] **Step 1: Создать fake-system test для Codex lifecycle**

```lua
vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/nvim")

local runner_module = require "config.ai.headless_runner"

local calls = {}
local callbacks = {}
local handles = {}

local function fake_system(cmd, opts, callback)
  table.insert(calls, { cmd = cmd, opts = opts })
  table.insert(callbacks, callback)
  local handle = {
    pid = 1000 + #calls,
    signals = {},
    kill = function(self, signal) table.insert(self.signals, signal) end,
  }
  table.insert(handles, handle)
  return handle
end

local runner = runner_module.new {
  system = fake_system,
  executable = function() return true end,
  mkdir = function() return true end,
  now = function() return "20260906-120000" end,
  state_dir = "/state",
  worktree_wrapper = "/runtime/create-worktree",
}

local id = assert(runner:start {
  provider = "codex",
  mode = "write",
  prompt = "Implement the comparison",
  repo = "/repo",
  repo_name = "repo",
})
assert(runner:get(id).status == "creating_worktree")
assert(calls[1].cmd[1] == "/runtime/create-worktree")

callbacks[1] {
  code = 0,
  stdout = [[{"format_version":1,"repository":"/repo","worktree":"/wt","branch":"ai/codex-1","base_ref":"origin/main"}]],
  stderr = "",
}
vim.wait(20)
assert(runner:get(id).status == "running")
assert(calls[2].opts.cwd == "/wt")

callbacks[2] { code = 0, stdout = "Completed", stderr = "progress" }
vim.wait(20)
assert(runner:get(id).status == "succeeded")
assert(runner:get(id).stdout == "Completed")
assert(runner:get(id).worktree == "/wt")

print "headless_runner_spec: ok"
```

- [ ] **Step 2: Добавить failure, cancellation и Claude cases**

В том же файле добавить отдельные runner instances и assertions:

```lua
local failed_runner = runner_module.new {
  system = fake_system,
  executable = function() return true end,
  mkdir = function() return true end,
  now = function() return "20260906-120001" end,
  state_dir = "/state",
  worktree_wrapper = "/runtime/create-worktree",
}
local failed_id = assert(failed_runner:start {
  provider = "claude",
  mode = "read",
  prompt = "Analyze",
  repo = "/repo",
  repo_name = "repo",
})
callbacks[#callbacks] { code = 1, stdout = "", stderr = "fetch failed" }
vim.wait(20)
assert(failed_runner:get(failed_id).status == "failed")
assert(failed_runner:get(failed_id).stderr == "fetch failed")

local cancel_id = assert(runner:start {
  provider = "codex",
  mode = "read",
  prompt = "Analyze",
  repo = "/repo",
  repo_name = "repo",
})
callbacks[#callbacks] {
  code = 0,
  stdout = [[{"format_version":1,"repository":"/repo","worktree":"/wt-2","branch":"ai/codex-2","base_ref":"origin/main"}]],
  stderr = "",
}
vim.wait(20)
assert(runner:cancel(cancel_id))
assert(handles[#handles].signals[1] == "sigterm")
assert(runner:get(cancel_id).status == "canceled")
```

- [ ] **Step 3: Запустить тест и подтвердить ожидаемый RED**

```sh
nvim --headless -u NONE -l nvim/tests/headless_runner_spec.lua
```

Expected: exit non-zero с `module 'config.ai.headless_runner' not found`.

### Task 4: Реализовать in-memory runner

**Files:**

- Create: `nvim/lua/config/ai/headless_runner.lua`
- Test: `nvim/tests/headless_runner_spec.lua`

- [ ] **Step 1: Реализовать dependency-injected runner constructor**

```lua
local providers = require "config.ai.headless_providers"

local M = {}
local Runner = {}
Runner.__index = Runner

function M.new(dependencies)
  dependencies = dependencies or {}
  return setmetatable({
    jobs = {},
    counter = 0,
    system = dependencies.system or vim.system,
    executable = dependencies.executable or function(name) return vim.fn.executable(name) == 1 end,
    mkdir = dependencies.mkdir or function(path) return vim.fn.mkdir(path, "p") == 1 end,
    now = dependencies.now or function() return os.date "%Y%m%d-%H%M%S" end,
    state_dir = dependencies.state_dir or vim.fn.stdpath "state",
    on_update = dependencies.on_update or function() end,
    worktree_wrapper = dependencies.worktree_wrapper
      or vim.fn.expand "~/.agents/skills/git-worktree/scripts/create-worktree",
  }, Runner)
end

function Runner:get(id) return self.jobs[id] end

function Runner:_set_status(job, status)
  if job.status == status then return end
  job.status = status
  self.on_update(job)
end

function Runner:all()
  local result = vim.tbl_values(self.jobs)
  table.sort(result, function(left, right) return left.created_at > right.created_at end)
  return result
end
```

- [ ] **Step 2: Реализовать worktree-first start**

```lua
function Runner:start(request)
  assert(request.provider == "codex" or request.provider == "claude", "Unsupported AI provider")
  assert(request.mode == "read" or request.mode == "write", "Unsupported AI job mode")
  assert(request.prompt and vim.trim(request.prompt) ~= "", "AI job prompt is required")

  if not self.executable(request.provider) then return nil, request.provider .. " executable was not found" end
  if not self.executable(self.worktree_wrapper) then return nil, "Canonical worktree helper was not found" end

  self.counter = self.counter + 1
  local suffix = ("%s-%d"):format(self.now(), self.counter)
  local id = ("%s-%s"):format(request.provider, suffix)
  local branch_name = "ai/" .. id
  local parent = table.concat({ self.state_dir, "ai-jobs", "worktrees", request.repo_name }, "/")
  local worktree_path = parent .. "/" .. id
  if not self.mkdir(parent) then return nil, "Cannot create AI job state directory: " .. parent end

  local job = {
    id = id,
    provider = request.provider,
    mode = request.mode,
    prompt = request.prompt,
    repo = request.repo,
    created_at = suffix,
    status = "creating_worktree",
    stdout = "",
    stderr = "",
  }
  self.jobs[id] = job

  local command = providers.worktree_command {
    wrapper = self.worktree_wrapper,
    repo = request.repo,
    path = worktree_path,
    name = branch_name,
  }
  job.handle = self.system(command, { cwd = request.repo, text = true }, function(result)
    vim.schedule(function() self:_after_worktree(job, result) end)
  end)
  return id, nil
end
```

- [ ] **Step 3: Реализовать provider dispatch и terminal states**

```lua
function Runner:_after_worktree(job, result)
  if result.code ~= 0 then
    job.stderr = result.stderr or "Worktree creation failed"
    self:_set_status(job, "failed")
    return
  end

  local worktree, err = providers.parse_worktree_json(result.stdout)
  if not worktree then
    job.stderr = err
    self:_set_status(job, "failed")
    return
  end
  job.worktree = worktree.worktree
  job.branch = worktree.branch
  self:_set_status(job, "starting")

  local spec = providers[job.provider] {
    mode = job.mode,
    cwd = job.worktree,
    name = job.id,
    prompt = job.prompt,
  }
  job.handle = self.system(spec.cmd, {
    cwd = spec.cwd,
    text = true,
    stdin = spec.stdin,
  }, function(provider_result)
    vim.schedule(function() self:_after_provider(job, provider_result) end)
  end)
  self:_set_status(job, "running")
end

function Runner:_after_provider(job, result)
  job.stdout = result.stdout or ""
  job.stderr = result.stderr or ""

  if result.code ~= 0 then
    self:_set_status(job, "failed")
    return
  end
  if job.provider == "claude" then
    job.remote_id = providers.parse_claude_id(job.stdout)
    if not job.remote_id then
      job.stderr = "Claude did not return a background job id"
      self:_set_status(job, "failed")
      return
    end
    self:_set_status(job, "running")
    return
  end
  self:_set_status(job, "succeeded")
end
```

- [ ] **Step 4: Реализовать cancel и Claude refresh**

```lua
function Runner:cancel(id)
  local job = self.jobs[id]
  if not job then return false, "Unknown AI job" end

  if job.provider == "claude" and job.remote_id then
    self.system({ "claude", "stop", job.remote_id }, { text = true }, function(result)
      vim.schedule(function()
        self:_set_status(job, result.code == 0 and "canceled" or "failed")
        if result.code ~= 0 then job.stderr = result.stderr or "Claude stop failed" end
      end)
    end)
  elseif job.handle then
    job.handle:kill "sigterm"
    self:_set_status(job, "canceled")
  end
  return true, nil
end

function Runner:shutdown_local()
  for _, job in pairs(self.jobs) do
    local active = job.status == "creating_worktree" or job.status == "starting" or job.status == "running"
    if active and job.provider == "codex" and job.handle then
      job.handle:kill "sigterm"
      self:_set_status(job, "canceled")
    end
  end
end

function Runner:refresh_claude(callback)
  self.system({ "claude", "agents", "--json", "--all" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        local ok, sessions = pcall(vim.json.decode, result.stdout or "[]")
        if ok then
          local by_id = {}
          for _, session in ipairs(sessions) do by_id[session.id] = session end
          for _, job in pairs(self.jobs) do
            local session = job.remote_id and by_id[job.remote_id]
            if session then
              local status = ({ working = "running", done = "succeeded", stopped = "canceled" })[session.state]
                or session.state
              self:_set_status(job, status)
            end
          end
        end
      end
      callback(self:all())
    end)
  end)
end

return M
```

- [ ] **Step 5: Запустить tests и подтвердить GREEN**

```sh
nvim --headless -u NONE -l nvim/tests/headless_providers_spec.lua
nvim --headless -u NONE -l nvim/tests/headless_runner_spec.lua
```

Expected: оба scripts печатают `: ok` и завершаются с exit 0.

### Task 5: Добавить команды и scratch-buffer UI

**Files:**

- Create: `nvim/lua/config/ai/headless_jobs.lua`
- Create: `nvim/lua/plugins/ai/headless-jobs.lua`

- [ ] **Step 1: Реализовать commands вокруг одного default runner**

`headless_jobs.lua` должен создать один `runner = require("config.ai.headless_runner").new()`
и зарегистрировать:

```lua
local M = {}

local runner
local timer = vim.uv.new_timer()
local terminal_status = { succeeded = true, failed = true, canceled = true, blocked = true }

local function stop_polling()
  if timer:is_active() then timer:stop() end
end

local function poll_claude()
  runner:refresh_claude(function(jobs)
    local active = false
    for _, job in ipairs(jobs) do
      if job.provider == "claude" and (job.status == "running" or job.status == "blocked") then
        active = true
        break
      end
    end
    if not active then stop_polling() end
  end)
end

local function ensure_polling()
  if not timer:is_active() then timer:start(5000, 5000, vim.schedule_wrap(poll_claude)) end
end

runner = require("config.ai.headless_runner").new {
  on_update = function(job)
    if job.provider == "claude" and job.status == "running" then ensure_polling() end
    if not terminal_status[job.status] then return end
    local level = job.status == "failed" and vim.log.levels.ERROR or vim.log.levels.INFO
    vim.notify(("%s: %s"):format(job.id, job.status), level, { title = "AI jobs" })
  end,
}

local function git_root()
  local start = vim.api.nvim_buf_get_name(0)
  if start == "" then start = vim.fn.getcwd() end
  return vim.fs.root(start, ".git")
end

local function open_buffer(job, lines)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = "markdown"
  vim.api.nvim_buf_set_name(buffer, "ai-job://" .. job.id)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false
  vim.api.nvim_set_current_buf(buffer)
end

local function select_job(prompt, callback)
  runner:refresh_claude(function(jobs)
    vim.ui.select(jobs, {
      prompt = prompt,
      format_item = function(job)
        return ("[%s] %s %s %s"):format(job.status, job.provider, job.mode, job.id)
      end,
    }, callback)
  end)
end
```

- [ ] **Step 2: Реализовать start/list/open/cancel flows**

```lua
function M.start(provider, mode)
  local repo = git_root()
  if not repo then
    vim.notify("AI jobs require a Git repository", vim.log.levels.ERROR, { title = "AI jobs" })
    return
  end
  vim.ui.input({ prompt = "AI job: " }, function(prompt)
    prompt = vim.trim(prompt or "")
    if prompt == "" then return end
    local id, err = runner:start {
      provider = provider,
      mode = mode,
      prompt = prompt,
      repo = repo,
      repo_name = vim.fs.basename(repo),
    }
    if not id then
      vim.notify(err, vim.log.levels.ERROR, { title = "AI jobs" })
      return
    end
    vim.notify("Started " .. id, vim.log.levels.INFO, { title = "AI jobs" })
  end)
end

function M.list()
  runner:refresh_claude(function(jobs)
    local lines = { "# AI Jobs", "" }
    for _, job in ipairs(jobs) do
      table.insert(lines, ("- `%s` | %s | %s | `%s`"):format(job.status, job.provider, job.mode, job.id))
    end
    open_buffer({ id = "list" }, lines)
  end)
end

function M.open()
  select_job("Open AI job", function(job)
    if not job then return end
    if job.provider == "claude" and job.remote_id then
      vim.system({ "claude", "logs", job.remote_id }, { text = true }, function(result)
        vim.schedule(function()
          local body = result.code == 0 and result.stdout or result.stderr
          open_buffer(job, vim.split(body or "No output", "\n", { plain = true }))
        end)
      end)
      return
    end
    local body = job.stdout ~= "" and job.stdout or job.stderr
    open_buffer(job, vim.split(body ~= "" and body or "No output yet", "\n", { plain = true }))
  end)
end

function M.cancel()
  select_job("Cancel AI job", function(job)
    if not job then return end
    local ok, err = runner:cancel(job.id)
    vim.notify(ok and ("Canceled " .. job.id) or err, ok and vim.log.levels.INFO or vim.log.levels.ERROR, {
      title = "AI jobs",
    })
  end)
end
```

- [ ] **Step 3: Зарегистрировать commands с completion**

```lua
function M.setup()
  vim.api.nvim_create_user_command("AIJobStart", function(command)
    local args = vim.split(command.args, "%s+", { trimempty = true })
    local provider = args[1]
    local mode = args[2]
    if not vim.tbl_contains({ "codex", "claude" }, provider) then
      vim.notify("Provider must be codex or claude", vim.log.levels.ERROR, { title = "AI jobs" })
      return
    end
    if not vim.tbl_contains({ "read", "write" }, mode) then
      vim.notify("Mode must be read or write", vim.log.levels.ERROR, { title = "AI jobs" })
      return
    end
    M.start(provider, mode)
  end, {
    nargs = "+",
    complete = function(_, line)
      if not line:match "^%S+%s+%S+%s+" then return { "codex", "claude" } end
      return { "read", "write" }
    end,
    desc = "Start a headless AI job in an isolated worktree",
  })
  vim.api.nvim_create_user_command("AIJobList", M.list, { desc = "List AI jobs" })
  vim.api.nvim_create_user_command("AIJobOpen", M.open, { desc = "Open AI job output" })
  vim.api.nvim_create_user_command("AIJobCancel", M.cancel, { desc = "Cancel AI job" })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
      stop_polling()
      if not timer:is_closing() then timer:close() end
      runner:shutdown_local()
    end,
  })
end

return M
```

- [ ] **Step 4: Добавить astrocore mappings**

```lua
---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    init = function() require("config.ai.headless_jobs").setup() end,
    opts = function(_, opts)
      local maps = opts.mappings
      maps.n["<Leader>Ar"] = { "<Cmd>AIJobStart codex read<CR>", desc = "AI Job Start" }
      maps.n["<Leader>Aj"] = { "<Cmd>AIJobList<CR>", desc = "AI Job List" }
      maps.n["<Leader>Ao"] = { "<Cmd>AIJobOpen<CR>", desc = "AI Job Open" }
      maps.n["<Leader>Ax"] = { "<Cmd>AIJobCancel<CR>", desc = "AI Job Cancel" }
    end,
  },
}
```

`<leader>Ar` дает быстрый безопасный default. Claude и write mode остаются
доступны через `:AIJobStart claude read`, `:AIJobStart codex write` и
`:AIJobStart claude write`, без разрастания mappings.

- [ ] **Step 5: Проверить command registration headless**

```sh
nvim --headless "+lua assert(vim.fn.exists(':AIJobStart') == 2)" "+lua assert(vim.fn.exists(':AIJobList') == 2)" "+lua assert(vim.fn.exists(':AIJobOpen') == 2)" "+lua assert(vim.fn.exists(':AIJobCancel') == 2)" +qa
```

Expected: exit 0.

### Task 6: Документировать пользовательский workflow и границы

**Files:**

- Modify: `nvim/AI.md`

- [ ] **Step 1: Добавить третью AI-поверхность**

Зафиксировать разделение:

```markdown
- CodeCompanion: быстрый API chat и reviewable inline diff.
- claudecode.nvim: интерактивная Claude-сессия.
- Headless AI jobs: автономная задача в отдельном worktree, пока основной
  Neovim остается доступным.
```

- [ ] **Step 2: Добавить команды и примеры JTBD**

```vim
:AIJobStart codex read
:AIJobStart claude read
:AIJobStart codex write
:AIJobStart claude write
:AIJobList
:AIJobOpen
:AIJobCancel
```

Примеры prompt:

```text
Compare the current implementation with the previous release and report behavioral differences.
Brainstorm three minimal designs for the cache invalidation problem and recommend one.
Implement the approved parser change, run focused tests, and leave the diff uncommitted.
```

- [ ] **Step 3: Записать ограничения и recovery**

Документировать:

- worktree создается от `origin/HEAD`, основной dirty checkout не копируется;
- worktree и branch остаются после завершения для review;
- cleanup выполняется отдельно через `git-worktree`, никогда автоматически;
- Claude job переживает закрытие Neovim; Codex job нет;
- при `blocked` Claude job открыть через `claude attach <id>`;
- Claude `--bg` принимает prompt как process argument, поэтому в prompt нельзя
  помещать API keys, tokens или другие секреты;
- ни один режим не дает права на commit, push, PR или merge.

### Task 7: Проверить deterministic и live behavior

**Files:**

- Verify: `nvim/lua/config/ai/headless_providers.lua`
- Verify: `nvim/lua/config/ai/headless_runner.lua`
- Verify: `nvim/lua/config/ai/headless_jobs.lua`
- Verify: `nvim/lua/plugins/ai/headless-jobs.lua`
- Verify: `nvim/tests/headless_providers_spec.lua`
- Verify: `nvim/tests/headless_runner_spec.lua`
- Verify: `nvim/AI.md`

- [ ] **Step 1: Запустить deterministic tests**

```sh
nvim --headless -u NONE -l nvim/tests/headless_providers_spec.lua
nvim --headless -u NONE -l nvim/tests/headless_runner_spec.lua
stylua --check nvim
(cd nvim && selene .)
nvim --headless "+checkhealth" +qa
```

Expected: tests печатают `: ok`; format/lint завершаются с exit 0; pre-existing
health warnings записываются отдельно.

- [ ] **Step 2: Проверить worktree isolation без LLM-вызова**

Вызвать runner до завершения worktree creation, затем отменить до provider
dispatch. Проверить `git worktree list --porcelain` и убедиться, что новый path
находится под `stdpath("state")/ai-jobs/worktrees/`, branch имеет prefix `ai/`, а
`git status --short` основного checkout не изменился.

- [ ] **Step 3: После явного разрешения выполнить один сетевой read smoke на provider**

Codex prompt:

```text
Read README.md and return only its first Markdown heading. Do not modify files.
```

Claude prompt:

```text
Read README.md and return only its first Markdown heading. Do not modify files.
```

Expected: оба jobs становятся `succeeded`, результат открывается через
`:AIJobOpen`, `git status --short` чистый в созданных worktrees и основной
checkout не меняется. Не запускать эти вызовы без разрешения на внешние LLM
запросы.

- [ ] **Step 4: После явного разрешения выполнить один write isolation smoke**

Запустить write job с задачей изменить только отдельный тестовый Markdown-файл
в worktree и не выполнять Git-команды. Expected: файл меняется только в
выведенном job worktree; основной checkout, index и remote остаются без
изменений. Worktree сохранить для review, не удалять автоматически.

- [ ] **Step 5: Проверить failure и cancel вручную**

Временно передать несуществующий provider binary через test dependency и
подтвердить `failed`. Запустить долгий fake Codex process, выполнить
`:AIJobCancel` и подтвердить `canceled`. Для Claude выполнить `claude stop <id>`
через команду и подтвердить состояние `stopped` в `claude agents --json --all`.

- [ ] **Step 6: Проверить точный diff**

```sh
git diff --check -- nvim docs/plans/2026-09-06-neovim-headless-ai-jobs-plan.md
git status --short
```

Expected: diff check чистый; unrelated
`ai-agents/.codex/config.shared.toml` остается неизмененным этой задачей.

- [ ] **Step 7: Commit checkpoint только при отдельном разрешении**

Если пользователь отдельно разрешил commit:

```sh
git add nvim/lua/config/ai/headless_providers.lua \
  nvim/lua/config/ai/headless_runner.lua \
  nvim/lua/config/ai/headless_jobs.lua \
  nvim/lua/plugins/ai/headless-jobs.lua \
  nvim/tests/headless_providers_spec.lua \
  nvim/tests/headless_runner_spec.lua \
  nvim/AI.md
git commit -m "feat(nvim): add isolated headless AI jobs"
```

Без отдельного разрешения не выполнять `git add` и `git commit`.

---

## Self-Review

- **Coverage:** provider commands, mandatory worktree isolation, job lifecycle,
  UI, docs, deterministic tests и controlled live smokes имеют отдельные tasks.
- **Harness boundary:** Neovim не хранит persistent sessions, не управляет
  reasoning/tools, не создает queues и не применяет результаты автоматически.
- **Isolation:** provider получает только новый worktree path; dirty state
  основного checkout не копируется.
- **Type consistency:** provider specs содержат `cmd`, `cwd`, optional `stdin`;
  runner jobs используют единые `id`, `provider`, `mode`, `status`, `worktree`,
  `stdout`, `stderr`, `handle`, `remote_id`.
- **Проверка полноты:** план не содержит заглушек, неопределенных функций или
  скрытых error-handling steps.
- **Git authority:** commit остается условным checkpoint; push, PR, merge и
  cleanup отсутствуют.
