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
      {
        "<Leader>uM",
        function() Snacks.toggle.dim():toggle() end,
        desc = "Toggle Dim",
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
      opts.dim = vim.tbl_deep_extend("force", opts.dim or {}, {
        animate = {
          enabled = false,
        },
        scope = {
          siblings = false,
          treesitter = {
            blocks = {
              enabled = true,
              "function_declaration",
              "function_definition",
              "method_declaration",
              "method_definition",
              "class_declaration",
              "class_definition",
            },
          },
        },
      })

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
