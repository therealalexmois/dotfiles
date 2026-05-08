-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
local Snacks = require "snacks"

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = {
        notify = true,
        size = 1024 * 256,
        lines = 2000,
        line_length = false,
      },
      autopairs = true,
      cmp = true,
      diagnostics = { virtual_text = true, virtual_lines = false },
      highlighturl = true,
      notifications = true,
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },

    -- Vim options can be configured here
    options = {
      opt = {
        relativenumber = true,
        number = true,
        spell = false,
        signcolumn = "yes",
        wrap = false,
        laststatus = 3,
        cmdheight = 1,
      },
      g = {
        -- NOTE: `mapleader` and `maplocalleader` must be set before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
    },

    -- Mappings can be configured through AstroCore as well.
    mappings = {
      n = {
        -- Buffer navigation
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- Buffer actions
        ["<Leader>c"] = {
          function() Snacks.bufdelete.delete() end,
          desc = "Close buffer",
        },
        ["<Leader>bc"] = {
          function() Snacks.bufdelete.other() end,
          desc = "Close all except current",
        },
        ["<Leader>bC"] = {
          function() Snacks.bufdelete.all() end,
          desc = "Close all buffers",
        },
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(function(bufnr) Snacks.bufdelete.delete(bufnr) end)
          end,
          desc = "Close buffer from tabline",
        },
        ["<Leader>bD"] = {
          function()
            require("astroui.status.heirline").buffer_picker(function(bufnr) Snacks.bufdelete.delete(bufnr) end)
          end,
          desc = "Pick to close",
        },
        ["<Leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },

        -- Picker
        ["<Leader>fF"] = {
          function()
            Snacks.picker.files {
              hidden = true,
              ignored = true,
              exclude = { ".git" },
            }
          end,
          desc = "Find files (hidden + ignored, no .git)",
        },
        ["<Leader>fW"] = {
          function()
            Snacks.picker.grep {
              hidden = true,
              ignored = true,
              exclude = { ".git" },
            }
          end,
          desc = "Live Grep (hidden + ignored, no .git)",
        },
      },
    },
  },
}
