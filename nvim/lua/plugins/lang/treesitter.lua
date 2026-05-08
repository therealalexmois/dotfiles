---@type LazySpec
return {
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = require('astrocore').list_insert_unique(opts.ensure_installed, {
        'lua',
        'vim',
        'vimdoc',

        'python',
        'sql',
        'dockerfile',
        'bash',

        'yaml',
        'toml',
        'json',

        'javascript',
        'typescript',
        'tsx',
        'html',
        'css',

        'go',
        'rust',
      })
    end,
  },
}
