--- Claude Code agent surface (research, reports, agentic chat, native diffs).
--- Runs the `claude` CLI over the official IDE protocol, so it inherits the
--- subscription auth, MCP servers, subagents, skills and rules from Claude Code.
--- Kept separate from CodeCompanion (`<leader>A`) under `<leader>C`.
---@type LazySpec
return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeSend",
      "ClaudeCodeAdd",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeStatus",
    },
    init = function()
      local ok, wk = pcall(require, "which-key")
      if ok then wk.add { { "<leader>C", group = "Claude Code", mode = { "n", "v" } } } end

      if vim.fn.exists ":ClaudeResearch" > 0 then return end

      local function launch_research(topic)
        topic = vim.trim(topic or "")
        if topic == "" then return end

        local instruction = table.concat({
          "Use the research-report subagent if it is available.",
          "Research task: " .. topic,
          "",
          "Investigate thoroughly using the codebase and any enabled MCP/web tools.",
          "Then write a structured Markdown report under docs/research/ with sections:",
          "Summary, Findings, Risks/Tradeoffs, Recommendation, Open questions, Sources.",
        }, "\n")

        vim.fn.setreg("+", instruction)
        vim.fn.setreg('"', instruction)
        vim.cmd "ClaudeCode"
        vim.schedule(
          function()
            vim.notify(
              "Research prompt copied to clipboard — paste it into Claude to start the report.",
              vim.log.levels.INFO,
              { title = "Claude Code" }
            )
          end
        )
      end

      vim.api.nvim_create_user_command("ClaudeResearch", function(cmd)
        if cmd.args ~= "" then
          launch_research(cmd.args)
        else
          vim.ui.input({ prompt = "Research topic: " }, function(input) launch_research(input) end)
        end
      end, {
        nargs = "*",
        desc = "Open Claude Code seeded with a research-report instruction",
      })
    end,
    opts = {},
    keys = {
      { "<leader>Cc", "<cmd>ClaudeCode<cr>", desc = "Claude toggle", mode = { "n", "v" } },
      { "<leader>Cf", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude focus" },
      { "<leader>Cr", "<cmd>ClaudeCode --resume<cr>", desc = "Claude resume" },
      { "<leader>CC", "<cmd>ClaudeCode --continue<cr>", desc = "Claude continue" },
      { "<leader>Cm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Claude select model" },
      { "<leader>Cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude add current buffer" },
      { "<leader>Cs", "<cmd>ClaudeCodeSend<cr>", desc = "Claude send selection", mode = "v" },
      { "<leader>Ca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude accept diff" },
      { "<leader>Cd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude deny diff" },
      { "<leader>CR", "<cmd>ClaudeResearch<cr>", desc = "Claude research report" },
      { "<leader>CS", "<cmd>ClaudeCodeStatus<cr>", desc = "Claude status" },
    },
  },
}
