return {
  "catppuccin/nvim",
  name = "catppuccin",
  config = function() require("catppuccin").setup {} end,
  opts = {
    integrations = {
      nvimtree = false,
      ts_rainbow = false,
      aerial = true,
      dap = { enabled = true, enable_ui = true },
      mason = true,
      neotree = true,
      notify = true,
      semantic_tokens = true,
      symbols_outline = true,
      telescope = true,
      which_key = true,
    },
  },
}
