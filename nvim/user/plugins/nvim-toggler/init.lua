return {
  "nguyenvukhang/nvim-toggler",
  event = { "User AstroFile", "InsertEnter" },
  keys = {
    {
      "<leader>i",
      desc = "Toggle CursorWord",
    },
  },
  opts = {
    inverses = {
      ["True"] = "False",
      ["top"] = "bottom",
    },
  },
}
