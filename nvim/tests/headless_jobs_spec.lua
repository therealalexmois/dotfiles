vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/nvim")

local jobs_module = require "config.ai.headless_jobs"
local plugin_specs = dofile(vim.fn.getcwd() .. "/nvim/lua/plugins/ai/headless-jobs.lua")

local registered = {}
local notifications = {}
local list_buf = nil
local fake_jobs = {
  {
    id = "codex-job-1",
    provider = "codex",
    mode = "read",
    status = "running",
    prompt = "Inspect the repository",
    worktree = "/state/worktrees/codex-job-1",
    stdout = "",
    stderr = "",
  },
}
local fake_runner = {
  jobs = fake_jobs,
  on_update = function() end,
  system_calls = {},
}

function fake_runner:all() return self.jobs end

function fake_runner:start(request)
  self.started = request
  local job = {
    id = "codex-job-2",
    provider = request.provider,
    mode = request.mode,
    status = "creating_worktree",
    prompt = request.prompt,
    worktree_path = "/state/worktrees/codex-job-2",
    stdout = "",
    stderr = "",
  }
  table.insert(self.jobs, job)
  self.on_update(job)
  return "codex-job-2", nil
end

function fake_runner:cancel(id)
  self.canceled = id
  return true, nil
end

function fake_runner:refresh_claude(callback) callback(self:all()) end

function fake_runner:shutdown_local() self.shutdown = true end

function fake_runner:get(id)
  for _, job in ipairs(self.jobs) do
    if job.id == id then return job end
  end
end

function fake_runner:system(cmd, opts, callback)
  table.insert(self.system_calls, { cmd = cmd, opts = opts })
  callback { code = 0, stdout = "Claude log line", stderr = "" }
  return { kill = function() end }
end

local original_create_user_command = vim.api.nvim_create_user_command
vim.api.nvim_create_user_command = function(name, callback, opts)
  registered[name] = { callback = callback, opts = opts }
end

local original_notify = vim.notify
vim.notify = function(message, level, opts)
  table.insert(notifications, { message = message, level = level, opts = opts })
end

local original_create_buf = vim.api.nvim_create_buf
vim.api.nvim_create_buf = function()
  list_buf = original_create_buf(false, true)
  return list_buf
end

local state = jobs_module.setup {
  runner = fake_runner,
  system = function(...) return fake_runner:system(...) end,
  poll = false,
  repo = function() return "/repo" end,
}

assert(state.runner == fake_runner)
local plugin_opts = plugin_specs[1].opts(nil, {})
assert(plugin_opts.mappings.n["<leader>Ar"][1] == "<cmd>AIJobStart<cr>")
assert(plugin_opts.mappings.n["<leader>Aj"][1] == "<cmd>AIJobList<cr>")
assert(plugin_opts.mappings.n["<leader>Ao"][1] == "<cmd>AIJobOpen<cr>")
assert(plugin_opts.mappings.n["<leader>Ax"][1] == "<cmd>AIJobCancel<cr>")
for _, name in ipairs { "AIJobStart", "AIJobList", "AIJobOpen", "AIJobCancel" } do
  assert(registered[name], "missing command " .. name)
end

local start_completion = registered.AIJobStart.opts.complete("", "AIJobStart ", 12)
assert(vim.tbl_contains(start_completion, "codex"))
assert(vim.tbl_contains(start_completion, "claude"))
local mode_completion = registered.AIJobStart.opts.complete("", "AIJobStart codex ", 17)
assert(vim.tbl_contains(mode_completion, "read"))
assert(vim.tbl_contains(mode_completion, "write"))

registered.AIJobStart.callback { fargs = { "codex", "read", "Inspect", "the", "repository" } }
assert(fake_runner.started.provider == "codex")
assert(fake_runner.started.mode == "read")
assert(fake_runner.started.prompt == "Inspect the repository")
assert(fake_runner.started.repo == "/repo")

registered.AIJobList.callback {}
assert(list_buf and vim.api.nvim_buf_get_option(list_buf, "modifiable") == false)
local lines = vim.api.nvim_buf_get_lines(list_buf, 0, -1, false)
assert(lines[1]:find("codex%-job%-1", 1, false))
assert(lines[1]:find("running", 1, true))

local cancel_completion = registered.AIJobCancel.opts.complete("codex", "AIJobCancel codex", 14)
assert(vim.tbl_contains(cancel_completion, "codex-job-1"))
registered.AIJobCancel.callback { args = "codex-job-1", fargs = { "codex-job-1" } }
assert(fake_runner.canceled == "codex-job-1")

notifications = {}

table.insert(fake_runner.jobs, {
  id = "claude-job-1",
  provider = "claude",
  mode = "write",
  status = "running",
  remote_id = "remote-1",
  repo = "/repo",
  worktree = "/state/worktrees/claude-job-1",
})
registered.AIJobOpen.callback { args = "claude-job-1", fargs = { "claude-job-1" } }
vim.wait(20)
assert(fake_runner.system_calls[1].cmd[1] == "claude")
assert(fake_runner.system_calls[1].cmd[2] == "logs")
assert(fake_runner.system_calls[1].cmd[3] == "remote-1")
local log_lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false)
assert(log_lines[1] == "Claude log line")

fake_runner.on_update {
  id = "codex-job-1",
  provider = "codex",
  status = "succeeded",
}
assert(#notifications == 1)
assert(notifications[1].message:find("succeeded", 1, true))

vim.api.nvim_exec_autocmds("VimLeavePre", {})
assert(fake_runner.shutdown)

local previous_started = fake_runner.started
state.repo = function() return nil end
local no_git_id, no_git_error = state:start { provider = "codex", mode = "read", prompt = "No repository" }
assert(no_git_id == nil)
assert(no_git_error:find("Git repository", 1, true))
assert(fake_runner.started == previous_started)

state.repo = function() return "/repo" end
local early_failure_id = state.runner:start {
  provider = "codex",
  mode = "read",
  prompt = "Early failure",
  repo = "/repo",
}
local early_job = fake_runner:get(early_failure_id)
early_job.status = "failed"
fake_runner.on_update(early_job)
assert(notifications[#notifications].message:find("failed", 1, true))

vim.api.nvim_create_user_command = original_create_user_command
vim.notify = original_notify
vim.api.nvim_create_buf = original_create_buf

print "headless_jobs_spec: ok"
