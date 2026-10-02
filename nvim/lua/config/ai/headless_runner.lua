local providers = require "config.ai.headless_providers"

local M = {}
local Runner = {}
Runner.__index = Runner

local function is_terminal(job) return job.status == "succeeded" or job.status == "failed" or job.status == "canceled" end

local function is_active(job)
  return job.status == "creating_worktree"
    or job.status == "starting"
    or job.status == "running"
    or job.status == "blocked"
end

local function is_within(root, path)
  root = vim.fs.normalize(root)
  path = vim.fs.normalize(path)
  return root == "/" and path:sub(1, 1) == "/" or path == root or path:sub(1, #root + 1) == root .. "/"
end

local function canonical_repository(path)
  local has_parent = path == ".."
    or (type(path) == "string" and path:sub(1, 3) == "../")
    or (type(path) == "string" and path:find("/../", 1, true) ~= nil)
    or (type(path) == "string" and path:sub(-3) == "/..")
  if type(path) ~= "string" or path == "" or path:sub(1, 1) ~= "/" or has_parent then return nil end
  return vim.fs.normalize(path)
end

function M.repository_key(repository)
  local canonical = canonical_repository(repository)
  if not canonical then return nil, "AI job repository must be an absolute, traversal-free path" end
  local basename = canonical:match "([^/]+)$" or "repository"
  basename = basename:gsub("[^%w_.-]", "_")
  return ("%s-%s"):format(basename, vim.fn.sha256(canonical):sub(1, 16)), nil
end

function M.new(dependencies)
  dependencies = dependencies or {}
  return setmetatable({
    jobs = {},
    counter = 0,
    system = dependencies.system or vim.system,
    executable = dependencies.executable or function(name) return vim.fn.executable(name) == 1 end,
    mkdir = dependencies.mkdir or function(path) return vim.fn.mkdir(path, "p") == 1 end,
    now = dependencies.now or function() return os.date "%Y%m%d-%H%M%S" end,
    unique = dependencies.unique or function()
      local clock = vim.uv and vim.uv.hrtime or vim.loop.hrtime
      return vim.fn.sha256(("%s-%s"):format(os.time(), clock())):sub(1, 20)
    end,
    path_exists = dependencies.path_exists or function(path) return vim.uv.fs_stat(path) ~= nil end,
    realpath = dependencies.realpath or function(path) return vim.uv.fs_realpath(path) end,
    state_dir = dependencies.state_dir or vim.fn.stdpath "state",
    on_update = dependencies.on_update or function() end,
    worktree_wrapper = dependencies.worktree_wrapper
      or vim.fn.expand "~/.agents/skills/git-worktree/scripts/create-worktree",
    reserved_paths = {},
    stop_sequence = 0,
    refresh_sequence = 0,
  }, Runner)
end

function Runner:get(id) return self.jobs[id] end

function Runner:_set_status(job, status)
  if job.status == status then return end
  if is_terminal(job) then return end
  job.status = status
  self.on_update(job)
end

function Runner:all()
  local result = vim.tbl_values(self.jobs)
  table.sort(result, function(left, right) return left.created_at > right.created_at end)
  return result
end

function Runner:start(request)
  assert(request.provider == "codex" or request.provider == "claude", "Unsupported AI provider")
  assert(request.mode == "read" or request.mode == "write", "Unsupported AI job mode")
  assert(request.prompt and vim.trim(request.prompt) ~= "", "AI job prompt is required")
  assert(request.repo, "AI job repository is required")

  local repository = canonical_repository(request.repo)
  if not repository then return nil, "AI job repository must be an absolute, traversal-free path" end
  local repository_key, repository_error = M.repository_key(repository)
  if not repository_key then return nil, repository_error end

  if not self.executable(request.provider) then return nil, request.provider .. " executable was not found" end
  if not self.executable(self.worktree_wrapper) then return nil, "Canonical worktree helper was not found" end

  self.counter = self.counter + 1
  local token = tostring(self.unique()):gsub("[^%w_.-]", "")
  if token == "" then return nil, "AI job id generator returned an empty token" end
  local suffix = ("%s-%d-%s"):format(self.now(), self.counter, token)
  local id = ("%s-%s"):format(request.provider, suffix)
  local branch_name = "ai/" .. id
  local parent = table.concat({ self.state_dir, "ai-jobs", "worktrees", repository_key }, "/")
  local worktree_path = parent .. "/" .. id
  if self.path_exists(worktree_path) or self.reserved_paths[worktree_path] then
    return nil, "AI job worktree path already exists: " .. worktree_path
  end
  if not self.mkdir(parent) then return nil, "Cannot create AI job state directory: " .. parent end
  local state_root = self.realpath(self.state_dir)
  local parent_realpath = self.realpath(parent)
  if not state_root or not parent_realpath or not is_within(state_root, parent_realpath) then
    return nil, "AI job state directory is outside the configured state directory: " .. parent
  end
  self.reserved_paths[worktree_path] = true

  local job = {
    id = id,
    provider = request.provider,
    mode = request.mode,
    prompt = request.prompt,
    repo = repository,
    worktree_path = worktree_path,
    branch = branch_name,
    created_at = suffix,
    status = "creating_worktree",
    stdout = "",
    stderr = "",
  }
  self.jobs[id] = job

  local command = providers.worktree_command {
    wrapper = self.worktree_wrapper,
    repo = repository,
    path = worktree_path,
    name = branch_name,
  }
  job.handle = self.system(command, { cwd = repository, text = true }, function(result)
    vim.schedule(function() self:_after_worktree(job, result) end)
  end)
  return id, nil
end

function Runner:_after_worktree(job, result)
  if not is_active(job) or job.status ~= "creating_worktree" then return end
  if result.code ~= 0 then
    job.stderr = result.stderr or "Worktree creation failed"
    self:_set_status(job, "failed")
    return
  end

  local worktree, err = providers.parse_worktree_json(result.stdout, {
    repository = job.repo,
    worktree = job.worktree_path,
    branch = job.branch,
  })
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
  if job.provider == "claude" and job.cancel_requested then
    local late_id = result.code == 0 and providers.parse_claude_id(result.stdout)
    if late_id then
      job.remote_id = late_id
      self:_stop_claude(job, late_id)
    elseif result.code ~= 0 then
      job.stderr = result.stderr or "Claude launch failed after cancellation"
    end
    return
  end
  if not is_active(job) then return end
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

function Runner:_stop_claude(job, remote_id)
  if job.stop_requested or not remote_id or remote_id == "" then return end
  self.stop_sequence = self.stop_sequence + 1
  local stop_token = self.stop_sequence
  job.stop_requested = true
  job.stop_pending = true
  job.stop_token = stop_token
  self.system({ "claude", "stop", remote_id }, { text = true }, function(result)
    vim.schedule(function()
      if job.stop_token ~= stop_token then return end
      job.stop_token = nil
      job.stop_pending = false
      if is_terminal(job) then return end
      if result.code == 0 then
        self:_set_status(job, "canceled")
      else
        job.stderr = result.stderr or "Claude stop failed"
        self:_set_status(job, "failed")
      end
    end)
  end)
end

function Runner:cancel(id)
  local job = self.jobs[id]
  if not job then return false, "Unknown AI job" end
  if not is_active(job) then return false, "AI job is not active" end
  if job.provider == "claude" and job.stop_pending then return true, nil end

  job.cancel_requested = true
  job.cancel_generation = (job.cancel_generation or 0) + 1

  if job.provider == "claude" and job.remote_id then
    self:_stop_claude(job, job.remote_id)
  elseif job.handle then
    job.handle:kill "sigterm"
    self:_set_status(job, "canceled")
  else
    self:_set_status(job, "canceled")
  end
  return true, nil
end

function Runner:shutdown_local()
  for _, job in pairs(self.jobs) do
    if is_active(job) and job.provider == "codex" and job.handle then
      job.handle:kill "sigterm"
      self:_set_status(job, "canceled")
    end
  end
end

function Runner:refresh_claude(callback)
  self.refresh_sequence = self.refresh_sequence + 1
  local refresh_sequence = self.refresh_sequence
  local generations = {}
  for id, job in pairs(self.jobs) do
    generations[id] = job.cancel_generation or 0
  end
  self.system({ "claude", "agents", "--json", "--all" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        local ok, sessions = pcall(vim.json.decode, result.stdout or "[]")
        if ok and type(sessions) == "table" then
          local by_id = {}
          for _, session in ipairs(sessions) do
            if type(session) == "table" and type(session.id) == "string" and session.id ~= "" then
              by_id[session.id] = session
            end
          end
          local states = {
            working = "running",
            blocked = "blocked",
            done = "succeeded",
            failed = "failed",
            stopped = "canceled",
          }
          if refresh_sequence == self.refresh_sequence then
            for _, job in pairs(self.jobs) do
              local session = job.remote_id and by_id[job.remote_id]
              local status = session and states[session.state]
              if
                status
                and not is_terminal(job)
                and not job.cancel_requested
                and generations[job.id] == (job.cancel_generation or 0)
              then
                self:_set_status(job, status)
              end
            end
          end
        end
      end
      callback(self:all())
    end)
  end)
end

return M
