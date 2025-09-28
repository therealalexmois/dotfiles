local function notify(msg, level, title)
  level = level or vim.log.levels.INFO
  title = title or "AI Commit"

  -- Fallback
  vim.notify(msg, level, { title = title })
end

return {
  "Kurama622/llm.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  cmd = {
    "LLMSessionToggle",
    "LLMSelectedTextHandler",
    "LLMAppHandler",
  },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = {
        mappings = {
          n = {
            -- review window then paste in LazyGit
            ["<Leader>Ac"] = { "<CMD>LLMAppHandler CommitMsg<CR>", desc = "AI Commit: review" },
            -- review window but pressing <CR> will also commit
            ["<Leader>AC"] = { "<CMD>LLMAppHandler CommitMsgQuick<CR>", desc = "AI Commit: review+commit" },
          },
        },
      },
    },
  },
  config = function()
    local tools = require "llm.tools"

    -- Robust streaming handler for Ollama's SSE ("data: {...}\n")
    local function ollama_streaming_handler(chunk, ctx, F)
      -- if you sometimes won't use F (e.g., quick tool), this silences “unused local”
      _ = F

      -- When streaming ends (plugin passes nil), return whatever we accumulated
      if not chunk then return ctx.assistant_output end

      local line = chunk:gsub("^data:%s*", ""):gsub("%s*$", "")
      ctx.line = (ctx.line or "") .. line
      if not ctx.line:match "}$" then return ctx.assistant_output or "" end

      -- Try to decode the JSON chunk
      local ok, data = pcall(vim.fn.json_decode, ctx.line)
      if not ok then
        -- Not a full JSON yet (or partial unicode), keep buffering
        return ctx.assistant_output or ""
      end

      -- Reset the line buffer after a successful decode
      ctx.line = ""

      -- Ollama final (non-stream) responses often look like:
      -- { message = { role = "assistant", content = "..." }, done = true, ... }
      -- Streaming deltas look similar, just smaller
      local content = (data and data.message and data.message.content) or data.error
      if content and content ~= "" then
        ctx.assistant_output = (ctx.assistant_output or "") .. content
        if F and F.WriteContent and ctx.bufnr and ctx.winid then
          F.WriteContent(ctx.bufnr, ctx.winid, content) -- live stream into window
        end
      end
      return ctx.assistant_output or ""
    end

    -- Final parse for non-stream (or end-of-stream) JSON
    local function ollama_parse_handler(obj)
      if type(obj) == "table" then
        if obj.message and type(obj.message) == "table" and obj.message.content then return obj.message.content end
        if obj.error then return "[ollama error] " .. tostring(obj.error) end
      end
      return ""
    end

    require("llm").setup {
      -- Direct chat endpoint of your local Ollama
      url = "http://127.0.0.1:11434/api/chat",
      model = "qwen2.5-coder:7b",
      streaming_handler = ollama_streaming_handler,

      -- Two “apps” (tools): review-first & one-shot
      app_handler = {
        -- 1) Review-first flow: shows a window, lets you copy/paste to LazyGit
        CommitMsg = {
          handler = tools.flexi_handler,
          prompt = function()
            local diff = vim.fn.system "git diff --no-ext-diff --staged"
            if diff == "" then
              notify("No staged changes. Stage files first.", vim.log.levels.WARN)
              return ""
            end
            local recent = vim.fn.system "git log --pretty=%s -n 30"

            return string.format(
              [[
  You are an expert at writing **Conventional Commits**.

  Rules:
  - Output plain text only (no code fences, no backticks, no emojis).
  - Subject format: <type>(<scope>): <subject>
    - types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
    - subject: imperative, no trailing period, <= 72 chars
  - Add an optional body (wrapped ~72 cols) with bullet points when useful.
  - Use a concise <scope> inferred from file paths (e.g., api, ui, tests, infra).

  You may look at recent commit subjects for style:
  ---
  %s
  ---

  Generate the final commit message based on this STAGED diff.

  STAGED DIFF:
  ```diff
  %s
  ]],
              recent,
              diff
            )
          end,
          opts = {
            parse_handler = ollama_parse_handler,
            enter_flexible_window = true,
            exit_on_move = false,
            apply_visual_selection = false,
            win_opts = { relative = "editor", position = "50%" },
            accept = {
              mapping = { mode = "n", keys = "<CR>" },
              action = function(ctx)
                local lines = vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, true)
                local msg = table.concat(lines, "\n")
                vim.fn.setreg("+", msg)
                notify("AI commit copied to clipboard (+). Paste in LazyGit.", vim.log.levels.INFO)
              end,
            },
          },
        },

        -- 2) One-shot flow: auto-commit with the generated message
        CommitMsgQuick = {
          handler = tools.flexi_handler,
          prompt = function()
            local diff = vim.fn.system "git diff --no-ext-diff --staged"
            if diff == "" then
              notify("No staged changes. Stage files first.", vim.log.levels.WARN)
              return ""
            end
            local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("%s+$", "")
            return string.format(
              [[
Write a Conventional Commit for branch %s.
Plain text only. No emojis, no code fences.

DIFF:
```diff
%s
```]],
              branch,
              diff
            )
          end,
          opts = {
            parse_handler = ollama_parse_handler,
            enter_flexible_window = true,
            exit_on_move = false,
            apply_visual_selection = false,
            win_opts = { relative = "editor", position = "50%", border = "rounded", focusable = true },
            accept = {
              mapping = { mode = "n", keys = "<CR>" },
              action = function(ctx)
                if ctx.winid and vim.api.nvim_win_is_valid(ctx.winid) then vim.api.nvim_set_current_win(ctx.winid) end

                local out = table.concat(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, true), "\n")
                -- copy first (so user can reuse it)
                vim.fn.setreg("+", out)

                -- escape for shell commit
                local msg = out:gsub('"', '\\"'):gsub("[$`\\]", "\\%0"):gsub("#", "\\#")
                notify("Committing…", vim.log.levels.INFO)
                vim.cmd(('!git commit -m "%s"'):format(msg))
              end,
            },
          },
        },
      },
    }
  end,
}
