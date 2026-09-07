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

local function run_callback(index, result)
  assert(callbacks[index], "missing callback " .. index)
  callbacks[index](result)
  vim.wait(20)
end

local function worktree_result(index)
  local command = calls[index].cmd
  return vim.json.encode {
    format_version = 1,
    repository = command[5],
    worktree = command[7],
    branch = command[3],
    base_ref = "origin/main",
  }
end

local updates = {}
local runner = runner_module.new {
  system = fake_system,
  executable = function() return true end,
  mkdir = function() return true end,
  realpath = function(path) return path end,
  now = function() return "20260906-120000" end,
  state_dir = "/state",
  worktree_wrapper = "/runtime/create-worktree",
  on_update = function(job) table.insert(updates, { id = job.id, status = job.status }) end,
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
assert(calls[1].opts.cwd == "/repo")
assert(calls[1].cmd[3]:find "^ai/codex%-20260906%-120000%-1%-")
assert(not calls[1].cmd[#calls[1].cmd]:find("Implement", 1, true))

run_callback(1, {
  code = 0,
  stdout = worktree_result(1),
  stderr = "",
})
assert(runner:get(id).status == "running")
assert(calls[2].opts.cwd == calls[1].cmd[7])
assert(calls[2].opts.stdin:find("Implement the comparison", 1, true))

run_callback(2, { code = 0, stdout = "Completed", stderr = "progress" })
assert(runner:get(id).status == "succeeded")
assert(runner:get(id).stdout == "Completed")
assert(runner:get(id).stderr == "progress")
assert(runner:get(id).worktree == calls[1].cmd[7])
assert(runner:get(id).branch == calls[1].cmd[3])

local failed_runner = runner_module.new {
  system = fake_system,
  executable = function() return true end,
  mkdir = function() return true end,
  realpath = function(path) return path end,
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
run_callback(#callbacks, { code = 1, stdout = "", stderr = "fetch failed" })
assert(failed_runner:get(failed_id).status == "failed")
assert(failed_runner:get(failed_id).stderr == "fetch failed")

local malformed_id = assert(failed_runner:start {
  provider = "codex",
  mode = "read",
  prompt = "Analyze",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, { code = 0, stdout = "{}", stderr = "" })
assert(failed_runner:get(malformed_id).status == "failed")
assert(failed_runner:get(malformed_id).stderr:find("unsupported", 1, true))

local cancel_id = assert(runner:start {
  provider = "codex",
  mode = "read",
  prompt = "Analyze",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, {
  code = 0,
  stdout = worktree_result(#callbacks),
  stderr = "",
})
assert(runner:cancel(cancel_id))
assert(handles[#handles].signals[1] == "sigterm")
assert(runner:get(cancel_id).status == "canceled")

local claude_id = assert(runner:start {
  provider = "claude",
  mode = "write",
  prompt = "Background work",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, {
  code = 0,
  stdout = worktree_result(#callbacks),
  stderr = "",
})
assert(runner:get(claude_id).status == "running")
run_callback(#callbacks, { code = 0, stdout = "backgrounded · remote-123 · Background work\n", stderr = "" })
assert(runner:get(claude_id).remote_id == "remote-123")
assert(runner:cancel(claude_id))
assert(calls[#calls].cmd[1] == "claude")
assert(calls[#calls].cmd[2] == "stop")
assert(calls[#calls].cmd[3] == "remote-123")
run_callback(#callbacks, { code = 0, stdout = "stopped", stderr = "" })
assert(runner:get(claude_id).status == "canceled")

local refresh_id = assert(runner:start {
  provider = "claude",
  mode = "write",
  prompt = "Refresh mapping",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, { code = 0, stdout = worktree_result(#callbacks), stderr = "" })
run_callback(#callbacks, { code = 0, stdout = "backgrounded · remote-789 · Refresh mapping\n", stderr = "" })

local refresh_result
runner:refresh_claude(function(jobs) refresh_result = jobs end)
assert(calls[#calls].cmd[1] == "claude")
assert(calls[#calls].cmd[2] == "agents")
assert(calls[#calls].cmd[3] == "--json")
assert(calls[#calls].cmd[4] == "--all")
run_callback(#callbacks, {
  code = 0,
  stdout = '[{"id":"remote-789","state":"done"}]',
  stderr = "",
})
assert(refresh_result)
assert(runner:get(claude_id).status == "canceled")
assert(runner:get(refresh_id).status == "succeeded")

local malformed_refresh_result
runner:refresh_claude(function(jobs) malformed_refresh_result = jobs end)
run_callback(#callbacks, {
  code = 0,
  stdout = "[{}]",
  stderr = "",
})
assert(malformed_refresh_result, "Claude refresh must ignore entries without an id")

local blocked_id = assert(runner:start {
  provider = "claude",
  mode = "write",
  prompt = "Blocked mapping",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, { code = 0, stdout = worktree_result(#callbacks), stderr = "" })
run_callback(#callbacks, { code = 0, stdout = "backgrounded · remote-blocked · Blocked mapping\n", stderr = "" })
runner:refresh_claude(function() end)
run_callback(#callbacks, {
  code = 0,
  stdout = '[{"id":"remote-blocked","state":"blocked"}]',
  stderr = "",
})
assert(runner:get(blocked_id).status == "blocked")
runner:refresh_claude(function() end)
run_callback(#callbacks, {
  code = 0,
  stdout = '[{"id":"remote-blocked","state":"working"}]',
  stderr = "",
})
assert(runner:get(blocked_id).status == "running")
assert(runner:cancel(blocked_id))
run_callback(#callbacks, { code = 0, stdout = "stopped", stderr = "" })
assert(runner:get(blocked_id).status == "canceled")

local stop_failed_id = assert(runner:start {
  provider = "claude",
  mode = "write",
  prompt = "Stop failure",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, { code = 0, stdout = worktree_result(#callbacks), stderr = "" })
run_callback(#callbacks, { code = 0, stdout = "backgrounded · remote-stop-fail · Stop failure\n", stderr = "" })
assert(runner:cancel(stop_failed_id))
run_callback(#callbacks, { code = 1, stdout = "", stderr = "permission denied" })
assert(runner:get(stop_failed_id).status == "failed")
assert(runner:get(stop_failed_id).stderr == "permission denied")

local failed_state_id = assert(runner:start {
  provider = "claude",
  mode = "read",
  prompt = "Failed state mapping",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, { code = 0, stdout = worktree_result(#callbacks), stderr = "" })
run_callback(#callbacks, { code = 0, stdout = "backgrounded · remote-failed · Failed state mapping\n", stderr = "" })
runner:refresh_claude(function() end)
run_callback(#callbacks, {
  code = 0,
  stdout = '[{"id":"remote-failed","state":"failed"}]',
  stderr = "",
})
assert(runner:get(failed_state_id).status == "failed")

local stopped_state_id = assert(runner:start {
  provider = "claude",
  mode = "read",
  prompt = "Stopped state mapping",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, { code = 0, stdout = worktree_result(#callbacks), stderr = "" })
run_callback(
  #callbacks,
  { code = 0, stdout = "backgrounded · remote-stopped · Stopped state mapping\n", stderr = "" }
)
runner:refresh_claude(function() end)
run_callback(#callbacks, {
  code = 0,
  stdout = '[{"id":"remote-stopped","state":"stopped"}]',
  stderr = "",
})
assert(runner:get(stopped_state_id).status == "canceled")

local canceled_refresh_id = assert(runner:start {
  provider = "claude",
  mode = "write",
  prompt = "Cancel before refresh",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, {
  code = 0,
  stdout = worktree_result(#callbacks),
  stderr = "",
})
run_callback(#callbacks, { code = 0, stdout = "backgrounded · remote-456 · Cancel before refresh\n", stderr = "" })
assert(runner:cancel(canceled_refresh_id))
run_callback(#callbacks, { code = 0, stdout = "stopped", stderr = "" })
assert(runner:get(canceled_refresh_id).status == "canceled")
runner:refresh_claude(function() end)
run_callback(#callbacks, {
  code = 0,
  stdout = '[{"id":"remote-456","state":"working"}]',
  stderr = "",
})
assert(runner:get(canceled_refresh_id).status == "canceled")

local launch_failed_id = assert(runner:start {
  provider = "codex",
  mode = "read",
  prompt = "Provider failure",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, {
  code = 0,
  stdout = worktree_result(#callbacks),
  stderr = "",
})
run_callback(#callbacks, { code = 1, stdout = "partial", stderr = "provider unavailable" })
assert(runner:get(launch_failed_id).status == "failed")
assert(runner:get(launch_failed_id).stderr == "provider unavailable")

local wrong_worktree_id = assert(runner:start {
  provider = "codex",
  mode = "read",
  prompt = "Reject escaped worktree",
  repo = "/repo",
  repo_name = "repo",
})
local wrong_worktree_call_count = #calls
run_callback(wrong_worktree_call_count, {
  code = 0,
  stdout = [[{"format_version":1,"repository":"/repo","worktree":"/main-checkout","branch":"ai/codex-wrong","base_ref":"origin/main"}]],
  stderr = "",
})
assert(runner:get(wrong_worktree_id).status == "failed")
assert(#calls == wrong_worktree_call_count)

local key_one = assert(runner_module.repository_key "/worktrees/one/project")
local key_two = assert(runner_module.repository_key "/other/project")
assert(key_one ~= key_two)
assert(not key_one:find("%.%.", 1, false))
assert(not key_one:find("/", 1, true))
local invalid_key, invalid_key_error = runner_module.repository_key "/repo/../outside"
assert(invalid_key == nil)
assert(invalid_key_error:find("traversal", 1, true))

local collision_calls = {}
local collision_runner = runner_module.new {
  system = function(cmd, opts, callback)
    table.insert(collision_calls, { cmd = cmd, opts = opts, callback = callback })
    return { kill = function() end }
  end,
  executable = function() return true end,
  mkdir = function() return true end,
  realpath = function(path) return path end,
  path_exists = function(path) return path:find("collision", 1, true) ~= nil end,
  now = function() return "collision" end,
  state_dir = "/state",
  worktree_wrapper = "/runtime/create-worktree",
}
local collision_id, collision_error = collision_runner:start {
  provider = "codex",
  mode = "read",
  prompt = "Reject existing path",
  repo = "/repo",
  repo_name = "../outside",
}
assert(collision_id == nil)
assert(collision_error:find("exists", 1, true))
assert(#collision_calls == 0)

local restart_one = runner_module.new {
  system = function()
    return { kill = function() end }
  end,
  executable = function() return true end,
  mkdir = function() return true end,
  realpath = function(path) return path end,
  now = function() return "same-time" end,
  state_dir = "/state",
  worktree_wrapper = "/runtime/create-worktree",
}
local restart_two = runner_module.new {
  system = function()
    return { kill = function() end }
  end,
  executable = function() return true end,
  mkdir = function() return true end,
  realpath = function(path) return path end,
  now = function() return "same-time" end,
  state_dir = "/state",
  worktree_wrapper = "/runtime/create-worktree",
}
local restart_one_id = assert(restart_one:start {
  provider = "codex",
  mode = "read",
  prompt = "Restart one",
  repo = "/repo",
  repo_name = "repo",
})
local restart_two_id = assert(restart_two:start {
  provider = "codex",
  mode = "read",
  prompt = "Restart two",
  repo = "/repo",
  repo_name = "repo",
})
assert(restart_one_id ~= restart_two_id)

local shutdown_id = assert(runner:start {
  provider = "codex",
  mode = "read",
  prompt = "Long task",
  repo = "/repo",
  repo_name = "repo",
})
runner:shutdown_local()
assert(runner:get(shutdown_id).status == "canceled")
assert(handles[#handles].signals[1] == "sigterm")

local stop_count_before_repeat = #calls
local repeated_cancel_id = assert(runner:start {
  provider = "claude",
  mode = "write",
  prompt = "Repeated cancel",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, { code = 0, stdout = worktree_result(#callbacks), stderr = "" })
run_callback(#callbacks, { code = 0, stdout = "backgrounded · remote-repeat · Repeated cancel\n", stderr = "" })
assert(runner:cancel(repeated_cancel_id))
local repeated_stop_callback = #callbacks
local repeated_cancel_generation = runner:get(repeated_cancel_id).cancel_generation
assert(runner:cancel(repeated_cancel_id))
assert(#calls == stop_count_before_repeat + 3)
assert(runner:get(repeated_cancel_id).stop_pending)
assert(runner:get(repeated_cancel_id).cancel_generation == repeated_cancel_generation)
run_callback(repeated_stop_callback, { code = 0, stdout = "stopped", stderr = "" })
assert(runner:get(repeated_cancel_id).status == "canceled")
run_callback(repeated_stop_callback, { code = 1, stdout = "", stderr = "late failure" })
assert(runner:get(repeated_cancel_id).status == "canceled")

local overlap_id = assert(runner:start {
  provider = "claude",
  mode = "write",
  prompt = "Overlapping refresh",
  repo = "/repo",
  repo_name = "repo",
})
run_callback(#callbacks, { code = 0, stdout = worktree_result(#callbacks), stderr = "" })
run_callback(#callbacks, { code = 0, stdout = "backgrounded · remote-overlap · Overlapping refresh\n", stderr = "" })
runner:refresh_claude(function() end)
local stale_refresh_callback = #callbacks
runner:refresh_claude(function() end)
local current_refresh_callback = #callbacks
run_callback(current_refresh_callback, {
  code = 0,
  stdout = '[{"id":"remote-overlap","state":"working"}]',
  stderr = "",
})
run_callback(stale_refresh_callback, {
  code = 0,
  stdout = '[{"id":"remote-overlap","state":"blocked"}]',
  stderr = "",
})
assert(runner:get(overlap_id).status == "running")

local symlink_root_runner = runner_module.new {
  system = function()
    return { kill = function() end }
  end,
  executable = function() return true end,
  mkdir = function() return true end,
  path_exists = function() return false end,
  realpath = function(path)
    if path == "/state-link" then return "/state-real" end
    return "/state-real/" .. path:match "/ai%-jobs/worktrees/.*"
  end,
  now = function() return "symlink-root" end,
  unique = function() return "root" end,
  state_dir = "/state-link",
  worktree_wrapper = "/runtime/create-worktree",
}
local symlink_root_id = assert(symlink_root_runner:start {
  provider = "codex",
  mode = "read",
  prompt = "Allow symlinked state root",
  repo = "/repo",
})
assert(symlink_root_id)

local escaped_parent_calls = 0
local escaped_parent_runner = runner_module.new {
  system = function() escaped_parent_calls = escaped_parent_calls + 1 end,
  executable = function() return true end,
  mkdir = function() return true end,
  path_exists = function() return false end,
  realpath = function(path)
    if path == "/state-link" then return "/state-real" end
    if path:find("/ai-jobs/worktrees/", 1, true) then return "/outside" end
    return path
  end,
  now = function() return "symlink-parent" end,
  unique = function() return "parent" end,
  state_dir = "/state-link",
  worktree_wrapper = "/runtime/create-worktree",
}
local escaped_parent_id, escaped_parent_error = escaped_parent_runner:start {
  provider = "codex",
  mode = "read",
  prompt = "Reject symlinked parent",
  repo = "/repo",
}
assert(escaped_parent_id == nil)
assert(escaped_parent_error:find("state directory", 1, true))
assert(escaped_parent_calls == 0)

print "headless_runner_spec: ok"
