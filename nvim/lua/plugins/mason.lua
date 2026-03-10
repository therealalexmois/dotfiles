---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- Lua / Neovim config
        "lua-language-server",
        "stylua",
        "selene", -- Lua linter and static analyzer

        -- Python
        "basedpyright", -- Python LSP + fast live type diagnostics in editor
        "ruff", -- Python linter and formatter
        "mypy", -- Project type checker for CLI / CI, not planned as live editor diagnostics for now
        "debugpy", -- Python debugger adapter for nvim-dap

        -- SQL
        "sqls",
        "sqlfluff",

        -- Docker / Shell
        "docker-language-server",
        "hadolint", -- Dockerfile linter
        "bash-language-server",
        "shellcheck",
        "shfmt",

        -- Config files
        "yaml-language-server",
        "taplo", -- TOML language server / formatter
        "json-lsp",

        -- Occasional web work
        "vtsls", -- TypeScript / JavaScript language server
        "eslint-lsp",
        "html-lsp",
        "css-lsp",
        "emmet-ls", -- Fast HTML/CSS abbreviation expansion
        "prettierd",

        -- Uncomment when Go becomes active again
        -- 'gopls',
        -- 'delve',

        -- Uncomment when Rust becomes active again
        -- 'rust-analyzer',
        -- 'codelldb',
      },
    },
  },
}
