-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    colorscheme = "astrodark",
    highlights = {
      init = {},
      astrodark = {},
    },
    icons = {
      VimIcon = '',
      ScrollText = '',
      GitBranch = '',
      GitAdd = '',
      GitChange = '',
      GitDelete = '',

      LSPLoading1 = '⠋',
      LSPLoading2 = '⠙',
      LSPLoading3 = '⠹',
      LSPLoading4 = '⠸',
      LSPLoading5 = '⠼',
      LSPLoading6 = '⠴',
      LSPLoading7 = '⠦',
      LSPLoading8 = '⠧',
      LSPLoading9 = '⠇',
      LSPLoading10 = '⠏',
    },
    text_icons = {
      GitAdd = "[+]",
    },
    status = {
      attributes = {
        git_branch = { bold = false },
      },
      colors = {
        git_branch_fg = "#abcdef",
      },
      icon_highlights = {
        breadcrumbs = true,
        file_icon = {
          tabline = function(self) return self.is_active or self.is_visible end,
          statusline = true,
        },
      },
    },
    lazygit = {
      theme_path = vim.fs.normalize(vim.fn.stdpath "cache" .. "/lazygit-theme.yml"),
      theme = {
        [241] = { fg = "Special" },
        activeBorderColor = { fg = "MatchParen", bold = true },
        cherryPickedCommitBgColor = { fg = "Identifier" },
        cherryPickedCommitFgColor = { fg = "Function" },
        defaultFgColor = { fg = "Normal" },
        inactiveBorderColor = { fg = "FloatBorder" },
        optionsTextColor = { fg = "Function" },
        searchingActiveBorderColor = { fg = "MatchParen", bold = true },
        selectedLineBgColor = { bg = "Visual" },
        unstagedChangesColor = { fg = "DiagnosticError" },
      },
    },
  },
}
