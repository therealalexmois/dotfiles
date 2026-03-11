local Snacks = require "snacks"

---@type LazySpec
return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<Leader>fN",
        function() Snacks.notifier.show_history() end,
        desc = "Notification history",
      },
      {
        "<Leader>uo",
        function() Snacks.toggle.words():toggle() end,
        desc = "Toggle LSP Words",
      },
    },
    opts = function(_, opts)
      opts.input = vim.tbl_deep_extend("force", opts.input or {}, {
        icon = " ",
        prompt_pos = "title",
        expand = true,
        win = {
          style = "input",
        },
      })

      opts.notifier = vim.tbl_deep_extend("force", opts.notifier or {}, {
        timeout = 3000,
        level = vim.log.levels.INFO,
        style = "compact",
        top_down = true,
      })

      opts.bufdelete = opts.bufdelete or {}
      opts.toggle = opts.toggle or {}
      opts.rename = opts.rename or {}

      opts.words = vim.tbl_deep_extend("force", opts.words or {}, {
        modes = { "n" },
      })

      opts.styles = opts.styles or {}
      opts.styles.input = vim.tbl_deep_extend("force", opts.styles.input or {}, {
        backdrop = 30,
        relative = "cursor",
        row = -3,
        col = 0,
        width = 50,
        border = "rounded",
        title_pos = "center",
      })

      opts.dashboard = opts.dashboard or {}
      opts.dashboard.preset = opts.dashboard.preset or {}

      opts.dashboard.preset.header = table.concat({
        " █████  ███████ ████████ ██████   ██████ ",
        "██   ██ ██         ██    ██   ██ ██    ██",
        "███████ ███████    ██    ██████  ██    ██",
        "██   ██      ██    ██    ██   ██ ██    ██",
        "██   ██ ███████    ██    ██   ██  ██████ ",
        "",
        "███    ██ ██    ██ ██ ███    ███",
        "████   ██ ██    ██ ██ ████  ████",
        "██ ██  ██ ██    ██ ██ ██ ████ ██",
        "██  ██ ██  ██  ██  ██ ██  ██  ██",
        "██   ████   ████   ██ ██      ██",
      }, "\n")
    end,
  },
}
