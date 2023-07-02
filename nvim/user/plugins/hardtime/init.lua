local prefix = "<leader>u"
return {
  "m4xshen/hardtime.nvim",
  event = "User AstroFile",
  opts = {
    max_time = 1000,
    max_count = 3,
    disable_mouse = true,
    hint = true,
    notification = true,
    allow_different_key = false,
    disabled_keys = {
      ["<UP>"] = { "", "i" },
      ["<DOWN>"] = { "", "i" },
      ["<LEFT>"] = { "", "i" },
      ["<RIGHT>"] = { "", "i" },
      ["<Insert>"] = { "", "i" },
      ["<Home>"] = { "", "i" },
      ["<End>"] = { "", "i" },
      ["<PageUp>"] = { "", "i" },
      ["<PageDown>"] = { "", "i" },
    },
    disabled_filetypes = {
      "qf",
      "netrw",
      "NvimTree",
      "lazy",
      "mason",
      "prompt",
      "TelescopePrompt",
      "noice",
      "notify",
      "neo-tree",
    },
  },
  keys = {
    { prefix .. "x", "<cmd>Hardtime toggle<CR>", desc = "Toggle hardtime" },
  },

}
