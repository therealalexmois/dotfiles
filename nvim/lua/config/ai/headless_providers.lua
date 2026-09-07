local M = {}

local function is_absolute_path(value) return type(value) == "string" and value ~= "" and value:sub(1, 1) == "/" end

local function has_parent_component(value)
  return value == ".." or value:sub(1, 3) == "../" or value:find("/../", 1, true) ~= nil or value:sub(-3) == "/.."
end

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

function M.parse_worktree_json(stdout, expected)
  local ok, value = pcall(vim.json.decode, stdout or "")
  if not ok or type(value) ~= "table" or value.format_version ~= 1 then
    return nil, "Worktree helper returned an unsupported response"
  end
  if
    type(value.repository) ~= "string"
    or value.repository == ""
    or type(value.worktree) ~= "string"
    or value.worktree == ""
    or type(value.branch) ~= "string"
    or value.branch == ""
  then
    return nil, "Worktree helper response misses repository, worktree, or branch"
  end
  if not is_absolute_path(value.worktree) or has_parent_component(value.worktree) then
    return nil, "Worktree helper returned a non-absolute or unconfined worktree path"
  end
  if expected then
    if not is_absolute_path(expected.repository) or has_parent_component(expected.repository) then
      return nil, "Expected repository must be an absolute, traversal-free path"
    end
    if not is_absolute_path(expected.worktree) or has_parent_component(expected.worktree) then
      return nil, "Expected worktree must be an absolute, traversal-free path"
    end
    if value.repository ~= expected.repository then
      return nil, "Worktree helper response does not confirm the expected repository"
    end
    if value.worktree ~= expected.worktree then
      return nil, "Worktree helper response does not confirm the expected worktree"
    end
    if value.branch ~= expected.branch then
      return nil, "Worktree helper response does not confirm the expected branch"
    end
  end
  return value, nil
end

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

function M.parse_claude_id(stdout) return (stdout or ""):match "backgrounded%s+·%s+([%w-]+)" end

return M
