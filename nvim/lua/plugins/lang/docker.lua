--- # TODO: подумать как упростить файл
---@type LazySpec
return {
  {
    'AstroNvim/astrocore',
    ---@type AstroCoreOpts
    opts = {
      filetypes = {
        filename = {
          ['docker-compose.yaml'] = 'yaml.docker-compose',
          ['docker-compose.yml'] = 'yaml.docker-compose',
        },
      },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter',
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= 'all' then
        opts.ensure_installed = require('astrocore').list_insert_unique(opts.ensure_installed, {
          'dockerfile',
        })
      end
    end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      opts.ensure_installed = require('astrocore').list_insert_unique(opts.ensure_installed, {
        'dockerls',
      })
    end,
  },
  {
    'mfussenegger/nvim-lint',
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.dockerfile = require('astrocore').list_insert_unique(
        opts.linters_by_ft.dockerfile or {},
        { 'hadolint' }
      )
    end,
  },
}
