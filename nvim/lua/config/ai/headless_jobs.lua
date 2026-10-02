local runner_module = require "config.ai.headless_runner"

local M = {}
local current

local TERMINAL = {
  canceled = true,
  failed = true,
  succeeded = true,
}

local function notify(message, level) vim.notify(message, level or vim.log.levels.INFO, { title = "AI jobs" }) end

local function filter(values, prefix)
  local result = {}
  for _, value in ipairs(values) do
    if prefix == "" or value:sub(1, #prefix) == prefix then table.insert(result, value) end
  end
  return result
end

local function scratch(title, lines, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = filetype or "ai-job"
  pcall(vim.api.nvim_buf_set_name, buf, title)
  vim.api.nvim_set_current_buf(buf)
  return buf
end

local function jobs(state) return state.runner:all() end

local function current_git_root()
  local root = vim.fs.root(0, { ".git" })
  if root then return root end
  return vim.fs.root(vim.fn.getcwd(), { ".git" })
end

local function start_job(state, request)
  if request.provider ~= "codex" and request.provider ~= "claude" then
    notify("Choose codex or claude as the AI job provider", vim.log.levels.ERROR)
    return nil, "Unsupported AI provider"
  end
  if request.mode ~= "read" and request.mode ~= "write" then
    notify("Choose read or write as the AI job mode", vim.log.levels.ERROR)
    return nil, "Unsupported AI job mode"
  end
  local repo = state.repo()
  if not repo or repo == "" then
    notify("Current buffer is not inside a Git repository", vim.log.levels.ERROR)
    return nil, "Git repository was not found"
  end
  request.repo = repo
  local id, err = state.runner:start(request)
  if not id then
    notify(err or "Unable to start AI job", vim.log.levels.ERROR)
    return nil, err
  end
  local job = state.runner:get(id)
  if job then state.seen_status[id] = job.status end
  notify("Started " .. id)
  return id, nil
end

local function find_job(state, id)
  if not id or id == "" then return nil end
  return state.runner:get(id)
end

local function choose_job(state, prompt, callback, active_only)
  local items = {}
  for _, job in ipairs(jobs(state)) do
    if not active_only or not TERMINAL[job.status] then table.insert(items, job.id) end
  end
  if #items == 0 then
    notify("No AI jobs available", vim.log.levels.WARN)
    return
  end
  state.select(items, { prompt = prompt }, callback)
end

local function open_output(state, job, output, title)
  local lines = vim.split(output or "", "\n", { plain = true })
  if #lines == 0 or (#lines == 1 and lines[1] == "") then lines = { "(no output)" } end
  scratch(title, lines, "ai-job")
end

local function open_claude_logs(state, job)
  if not job.remote_id then
    notify("Claude job has no background id yet", vim.log.levels.WARN)
    return
  end
  state.system({ "claude", "logs", job.remote_id }, {
    cwd = job.worktree or job.repo,
    text = true,
  }, function(result)
    vim.schedule(function()
      local output = result.code == 0 and result.stdout or (result.stderr or result.stdout)
      if result.code ~= 0 then notify("Claude logs failed for " .. job.id, vim.log.levels.ERROR) end
      open_output(state, job, output, "AI job " .. job.id .. " logs")
    end)
  end)
end

local function list_jobs(state)
  local lines = {}
  for _, job in ipairs(jobs(state)) do
    local location = job.worktree or job.worktree_path or "worktree pending"
    local remote = job.remote_id and (" remote=" .. job.remote_id) or ""
    table.insert(lines, ("%s [%s] %s/%s - %s%s"):format(job.id, job.status, job.provider, job.mode, location, remote))
  end
  if #lines == 0 then lines = { "No AI jobs" } end
  return scratch("AI jobs", lines, "ai-job-list")
end

local function command_completion(kind)
  return function(arglead, cmdline, cursorpos)
    local before = cmdline:sub(1, cursorpos)
    local parts = vim.split(before, "%s+", { trimempty = true })
    if kind == "start" then
      local trailing_space = before:sub(-1) == " "
      if #parts == 1 or (#parts == 2 and not trailing_space) then return filter({ "codex", "claude" }, arglead) end
      if #parts == 2 or (#parts == 3 and not trailing_space) then return filter({ "read", "write" }, arglead) end
      return {}
    end
    local ids = {}
    for _, job in ipairs(jobs(current)) do
      table.insert(ids, job.id)
    end
    return filter(ids, arglead)
  end
end

local function create_command(name, callback, opts)
  if vim.fn.exists(":" .. name) == 2 then vim.api.nvim_del_user_command(name) end
  vim.api.nvim_create_user_command(name, callback, opts)
end

local function register_commands(state)
  create_command("AIJobStart", function(command)
    local fargs = command.fargs
    local provider = fargs[1]
    local mode = fargs[2]
    local prompt_parts = {}
    for index = 3, #fargs do
      table.insert(prompt_parts, fargs[index])
    end
    local prompt = table.concat(prompt_parts, " ")

    local function collect_prompt()
      if prompt ~= "" then
        state:start { provider = provider, mode = mode, prompt = prompt }
      else
        state.input({ prompt = "AI job prompt: " }, function(value)
          value = vim.trim(value or "")
          if value ~= "" then state:start { provider = provider, mode = mode, prompt = value } end
        end)
      end
    end

    local function collect_mode()
      if mode then
        collect_prompt()
      else
        state.select({ "read", "write" }, { prompt = "AI job mode: " }, function(value)
          mode = value
          if mode then collect_prompt() end
        end)
      end
    end

    if provider then
      collect_mode()
    else
      state.select({ "codex", "claude" }, { prompt = "AI job provider: " }, function(value)
        provider = value
        if provider then collect_mode() end
      end)
    end
  end, {
    nargs = "*",
    complete = command_completion "start",
    desc = "Start an isolated background AI job",
  })

  create_command("AIJobList", function() list_jobs(state) end, {
    nargs = 0,
    desc = "List background AI jobs",
  })

  create_command("AIJobOpen", function(command)
    local id = command.args ~= "" and command.args or nil
    local function open(id_to_open)
      local job = find_job(state, id_to_open)
      if not job then
        notify("Unknown AI job: " .. tostring(id_to_open), vim.log.levels.ERROR)
      elseif job.provider == "claude" then
        open_claude_logs(state, job)
      else
        open_output(state, job, job.stdout ~= "" and job.stdout or job.stderr, "AI job " .. job.id)
      end
    end
    if id then
      open(id)
    else
      choose_job(state, "Open AI job: ", open, false)
    end
  end, {
    nargs = "?",
    complete = command_completion "job",
    desc = "Open AI job output or Claude logs",
  })

  create_command("AIJobCancel", function(command)
    local id = command.args ~= "" and command.args or nil
    local function cancel(id_to_cancel)
      local ok, err = state.runner:cancel(id_to_cancel)
      if not ok then
        notify(err or "Unable to cancel AI job", vim.log.levels.ERROR)
      else
        notify("Cancellation requested for " .. id_to_cancel)
      end
    end
    if id then
      cancel(id)
    else
      choose_job(state, "Cancel AI job: ", cancel, true)
    end
  end, {
    nargs = "?",
    complete = command_completion "job",
    desc = "Cancel an active AI job",
  })
end

local function install_autocmd(state)
  local group = vim.api.nvim_create_augroup("AIHeadlessJobs", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if state.timer then
        state.timer:stop()
        state.timer:close()
        state.timer = nil
      end
      state.runner:shutdown_local()
    end,
    desc = "Stop Neovim-owned Codex jobs while leaving Claude jobs alive",
  })
end

local function install_polling(state, interval)
  if interval == false then return end
  local uv = vim.uv or vim.loop
  state.timer = uv.new_timer()
  state.timer:start(interval, interval, function()
    vim.schedule(function()
      state.runner:refresh_claude(function() end)
    end)
  end)
end

function M.setup(opts)
  if current then return current end
  opts = opts or {}
  local state = {
    runner = opts.runner or runner_module.new(),
    system = opts.system,
    input = opts.input or vim.ui.input,
    select = opts.select or vim.ui.select,
    repo = opts.repo or current_git_root,
    seen_status = {},
  }
  state.system = state.system or state.runner.system or vim.system
  state.start = function(_, request) return start_job(state, request) end
  for _, job in ipairs(state.runner:all()) do
    state.seen_status[job.id] = job.status
  end

  local previous_update = state.runner.on_update
  state.runner.on_update = function(job)
    if previous_update then previous_update(job) end
    local previous = state.seen_status[job.id]
    state.seen_status[job.id] = job.status
    if TERMINAL[job.status] and previous and previous ~= job.status then
      notify(
        ("%s %s: %s"):format(job.provider, job.id, job.status),
        job.status == "succeeded" and vim.log.levels.INFO or vim.log.levels.WARN
      )
    end
  end

  current = state
  register_commands(state)
  install_autocmd(state)
  install_polling(state, opts.poll == false and false or (opts.poll_interval or 5000))
  return state
end

function M.state() return current end

function M.start(request)
  assert(current, "AI jobs are not initialized")
  return current:start(request)
end

function M.list()
  assert(current, "AI jobs are not initialized")
  return list_jobs(current)
end

function M.open(id)
  assert(current, "AI jobs are not initialized")
  local job = find_job(current, id)
  if not job then return nil, "Unknown AI job: " .. tostring(id) end
  if job.provider == "claude" then
    open_claude_logs(current, job)
  else
    open_output(current, job, job.stdout, "AI job " .. job.id)
  end
  return true
end

function M.cancel(id)
  assert(current, "AI jobs are not initialized")
  return current.runner:cancel(id)
end

function M._reset_for_tests()
  if current and current.timer then
    current.timer:stop()
    current.timer:close()
  end
  current = nil
end

return M
