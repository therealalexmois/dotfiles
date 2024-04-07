local prefix = "<leader>L"
local maps = { n = {} }
local icon = vim.g.icons_enabled and " " or ""
maps.n[prefix] = { desc = icon .. "Log" }
require("astrocore").set_mappings(maps)

return {
  "chrisgrieser/nvim-chainsaw",
  event = "User AstroFile",
  opts = {},
  keys = {
    {
      prefix .. "v",
      function() require("chainsaw").variableLog() end,
      desc = "Variable log",
    },
    {
      prefix .. "o",
      function() require("chainsaw").objectLog() end,
      desc = "Object log",
    },
    {
      prefix .. "a",
      function() require("chainsaw").assertLog() end,
      desc = "Assert log",
    },
    {
      prefix .. "m",
      function() require("chainsaw").messageLog() end,
      desc = "Message log",
    },
    {
      prefix .. "b",
      function() require("chainsaw").beepLog() end,
      desc = "Beep log",
    },
    {
      prefix .. "t",
      function() require("chainsaw").timeLog() end,
      desc = "Time log",
    },
    {
      prefix .. "d",
      function() require("chainsaw").debugLog() end,
      desc = "Debug log",
    },
    {
      prefix .. "r",
      function() require("chainsaw").removeLogs() end,
      desc = "Remove all log statements",
    },
  },
}
