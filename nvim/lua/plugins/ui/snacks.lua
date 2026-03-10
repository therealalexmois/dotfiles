---@type LazySpec
return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.input = vim.tbl_deep_extend("force", opts.input or {}, {
        icon = " ",
        prompt_pos = "title",
        expand = true,
        win = {
          style = "input",
        },
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
