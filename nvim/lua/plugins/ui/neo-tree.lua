---@type LazySpec
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    -- Temporary: pin to 3.40.0. 3.41.0 hits E5108 `state.tree` nil on `move` under
    -- Neovim 0.12.2 (no fix in v3 releases or main as of 2026-06). Overrides AstroNvim's
    -- `version = "^3"`. Remove once upstream fixes the regression.
    version = "3.40.0",
    opts = function(_, opts)
      local events = require "neo-tree.events"

      local function on_move(data) require("snacks").rename.on_rename_file(data.source, data.destination) end

      opts.event_handlers = opts.event_handlers or {}

      vim.list_extend(opts.event_handlers, {
        { event = events.FILE_MOVED, handler = on_move },
        { event = events.FILE_RENAMED, handler = on_move },
      })
    end,
  },
}
