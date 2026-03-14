-- lua/plugins/neogen.lua
return {
  'danymat/neogen',
  opts = function(_, opts)
    opts = opts or {}
    opts.languages = opts.languages or {}
    opts.languages.python = vim.tbl_deep_extend('force', opts.languages.python or {}, {
      template = {
        annotation_convention = 'google_docstrings',
      },
    })

    return opts
  end,
}
