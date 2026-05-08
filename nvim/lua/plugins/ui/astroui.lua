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
      astrodark = {
        LspReferenceText = { bold = true, underline = true },
        LspReferenceRead = { bold = true, underline = true },
        LspReferenceWrite = { bold = true, underline = true },
      },
    },
    icons = {
      VimIcon = "",
      ScrollText = "",
      GitBranch = "",
      GitAdd = "",
      GitChange = "",
      GitDelete = "",

      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
    },
    text_icons = {
      GitAdd = "[+]",
    },
    status = {
      attributes = {
        buffer_active = { bold = true, italic = false },
        git_branch = { bold = false },
      },
      colors = {
        git_branch_fg = "#abcdef",

        buffer_fg = "#7D8590",
        buffer_bg = "#0B1220",

        buffer_visible_fg = "#9AA4B2",
        buffer_visible_bg = "#0F1726",
        buffer_visible_path_fg = "#6E7681",

        buffer_active_fg = "#E6EDF3",
        buffer_active_bg = "#17304D",
        buffer_active_path_fg = "#9CD7FF",
        buffer_active_close_fg = "#F47067",
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
      configure = true,
      config = {
        os = { editPreset = "nvim-remote" },
        gui = {
          nerdFontsVersion = "3",
        },
      },
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
      win = {
        style = "lazygit",
      },
    },
  },
}
