-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = function(_, opts)
    opts.treesitter = opts.treesitter or {}
    opts.treesitter.ensure_installed = require("astrocore").list_insert_unique(opts.treesitter.ensure_installed or {}, {
      "lua",
      "vim",
      "vimdoc",

      "python",
      "sql",
      "dockerfile",
      "bash",

      "yaml",
      "toml",
      "json",

      "javascript",
      "typescript",
      "tsx",
      "html",
      "css",

      "go",
      "rust",
    })

    return require("astrocore").extend_tbl(opts, {
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

      filetypes = {
        filename = {
          ["docker-compose.yml"] = "yaml.docker-compose",
        },
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

          -- Disable unused remote-plugin providers (silences :checkhealth warnings)
          loaded_perl_provider = 0,
          loaded_ruby_provider = 0,
          loaded_python3_provider = 0,
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
            function() require("snacks").bufdelete.delete() end,
            desc = "Close buffer",
          },
          ["<Leader>bc"] = {
            function() require("snacks").bufdelete.other() end,
            desc = "Close all except current",
          },
          ["<Leader>bC"] = {
            function() require("snacks").bufdelete.all() end,
            desc = "Close all buffers",
          },
          ["<Leader>bd"] = {
            function()
              require("astroui.status.heirline").buffer_picker(
                function(bufnr) require("snacks").bufdelete.delete(bufnr) end
              )
            end,
            desc = "Close buffer from tabline",
          },
          ["<Leader>bD"] = {
            function()
              require("astroui.status.heirline").buffer_picker(
                function(bufnr) require("snacks").bufdelete.delete(bufnr) end
              )
            end,
            desc = "Pick to close",
          },
          ["<Leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },

          -- Picker
          ["<Leader>fF"] = {
            function()
              require("snacks").picker.files {
                hidden = true,
                ignored = true,
                exclude = { ".git" },
              }
            end,
            desc = "Find files (hidden + ignored, no .git)",
          },
          ["<Leader>fW"] = {
            function()
              require("snacks").picker.grep {
                hidden = true,
                ignored = true,
                exclude = { ".git" },
              }
            end,
            desc = "Live Grep (hidden + ignored, no .git)",
          },
        },
      },
    })
  end,
}
