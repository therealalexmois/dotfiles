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
  [[{"format_version":1,"repository":"/repo","worktree":"/wt","branch":"ai/codex-1","base_ref":"origin/main"}]],
  { repository = "/repo", worktree = "/wt", branch = "ai/codex-1" }
)
eq(parsed.worktree, "/wt")
eq(parsed.branch, "ai/codex-1")

local escaped, escaped_error = providers.parse_worktree_json(
  [[{"format_version":1,"repository":"/repo","worktree":"/main-checkout","branch":"ai/codex-1"}]],
  { repository = "/repo", worktree = "/wt", branch = "ai/codex-1" }
)
assert(escaped == nil)
assert(escaped_error:find("worktree", 1, true))

local wrong_repository, repository_error = providers.parse_worktree_json(
  [[{"format_version":1,"repository":"/other/repo","worktree":"/wt","branch":"ai/codex-1"}]],
  { repository = "/repo", worktree = "/wt", branch = "ai/codex-1" }
)
assert(wrong_repository == nil)
assert(repository_error:find("repository", 1, true))

local relative_path, relative_error = providers.parse_worktree_json(
  [[{"format_version":1,"repository":"/repo","worktree":"../wt","branch":"ai/codex-1"}]],
  { repository = "/repo", worktree = "../wt", branch = "ai/codex-1" }
)
assert(relative_path == nil)
assert(relative_error:find("absolute", 1, true))

local parent_path, parent_error = providers.parse_worktree_json(
  [[{"format_version":1,"repository":"/repo","worktree":"/repo/../wt","branch":"ai/codex-1"}]],
  { repository = "/repo", worktree = "/repo/../wt", branch = "ai/codex-1" }
)
assert(parent_path == nil)
assert(parent_error:find("unconfined", 1, true))

local wrong_branch, branch_error = providers.parse_worktree_json(
  [[{"format_version":1,"repository":"/repo","worktree":"/wt","branch":"ai/other"}]],
  { repository = "/repo", worktree = "/wt", branch = "ai/codex-1" }
)
assert(wrong_branch == nil)
assert(branch_error:find("branch", 1, true))

local invalid, invalid_error = providers.parse_worktree_json [[{"format_version":2}]]
assert(invalid == nil)
assert(invalid_error:find("unsupported", 1, true))

local codex = providers.codex {
  mode = "write",
  cwd = "/wt",
  prompt = "Compare both implementations",
}
eq(codex.cmd[1], "codex")
eq(codex.cmd[2], "-a")
eq(codex.cmd[3], "never")
eq(codex.cmd[4], "exec")
assert(vim.tbl_contains(codex.cmd, "workspace-write"))
assert(vim.tbl_contains(codex.cmd, "sandbox_workspace_write.network_access=false"))
eq(codex.cmd[#codex.cmd], "-")
eq(codex.cwd, "/wt")
assert(codex.stdin:find("Do not commit", 1, true))
assert(codex.stdin:find("Compare both implementations", 1, true))

local codex_read = providers.codex { mode = "read", cwd = "/wt", prompt = "Inspect" }
assert(vim.tbl_contains(codex_read.cmd, "read-only"))
assert(not vim.tbl_contains(codex_read.cmd, "workspace-write"))

local claude = providers.claude {
  mode = "read",
  cwd = "/wt",
  name = "claude-20260906-120000-1",
  prompt = "Brainstorm alternatives",
}
eq(claude.cmd[1], "claude")
eq(claude.cmd[2], "--bg")
assert(vim.tbl_contains(claude.cmd, "plan"))
assert(not vim.tbl_contains(claude.cmd, "-p"))
assert(not vim.tbl_contains(claude.cmd, "--dangerously-skip-permissions"))
eq(claude.cwd, "/wt")
assert(claude.cmd[#claude.cmd]:find("Do not modify files", 1, true))
assert(claude.cmd[#claude.cmd]:find("Brainstorm alternatives", 1, true))

local claude_write = providers.claude { mode = "write", cwd = "/wt", name = "claude-1", prompt = "Implement" }
assert(vim.tbl_contains(claude_write.cmd, "auto"))

eq(providers.parse_claude_id "backgrounded · 7c5dcf5d · example\n", "7c5dcf5d")
assert(providers.parse_claude_id "not backgrounded" == nil)

print "headless_providers_spec: ok"
