---@type LazySpec
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      local events = require "neo-tree.events"

      local function on_move(data)
        require("snacks").rename.on_rename_file(data.source, data.destination)
      end

      opts.event_handlers = opts.event_handlers or {}

      vim.list_extend(opts.event_handlers, {
        { event = events.FILE_MOVED, handler = on_move },
        { event = events.FILE_RENAMED, handler = on_move },
      })
    end,
  },
}
