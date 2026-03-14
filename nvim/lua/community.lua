--- Правила оформления
--- только **включённые** импорты;
--- пустая строка между секциями;
--- внутри секции — сортировка по алфавиту;
--- короткие комментарии-секции;
--- сначала foundation/UI, потом language packs, потом editing/search, потом git/docker, потом LSP/debugging, потом workflow/motion.
---@type LazySpec
return {
  "AstroNvim/astrocommunity",

  -- UI / colors / comments
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim" },
  { import = "astrocommunity.colorscheme.catppuccin" },
  { import = "astrocommunity.colorscheme.dracula-nvim" },
  { import = "astrocommunity.colorscheme.github-nvim-theme" },
  { import = "astrocommunity.colorscheme.rose-pine" },
  { import = "astrocommunity.colorscheme.vscode-nvim" },
  -- { import = "astrocommunity.comment.mini-comment" },

  -- Language packs
  { import = "astrocommunity.pack.bash" },
  { import = "astrocommunity.pack.helm" },
  { import = "astrocommunity.pack.html-css" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.just" },
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.python.ruff" },
  { import = "astrocommunity.pack.sql" },
  { import = "astrocommunity.pack.toml" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.yaml" },
  --
  -- -- Editing / search
  { import = "astrocommunity.editing-support.mini-splitjoin" },
  { import = "astrocommunity.editing-support.neogen" },
  { import = "astrocommunity.editing-support.nvim-devdocs" },
  { import = "astrocommunity.editing-support.nvim-regexplainer" },
  { import = "astrocommunity.editing-support.nvim-treesitter-context" },
  { import = "astrocommunity.editing-support.undotree" },
  { import = "astrocommunity.editing-support.vim-visual-multi" },
  { import = "astrocommunity.quickfix.nvim-bqf" },
  { import = "astrocommunity.search.nvim-spectre" },
  { import = "astrocommunity.syntax.hlargs-nvim" },
  { import = "astrocommunity.syntax.vim-cool" },
  { import = "astrocommunity.test.nvim-coverage" },
  { import = "astrocommunity.utility.nvim-toggler" },

  -- Git / Docker
  { import = "astrocommunity.docker.lazydocker" },
  { import = "astrocommunity.git.diffview-nvim" },

  -- LSP / debugging
  { import = "astrocommunity.debugging.nvim-chainsaw" },
  { import = "astrocommunity.debugging.nvim-dap-repl-highlights" },
  { import = "astrocommunity.debugging.nvim-dap-virtual-text" },
  { import = "astrocommunity.debugging.persistent-breakpoints-nvim" },
  { import = "astrocommunity.diagnostics.trouble-nvim" },
  { import = "astrocommunity.lsp.actions-preview-nvim" },
  { import = "astrocommunity.lsp.garbage-day-nvim" },
  { import = "astrocommunity.lsp.lsp-signature-nvim" },

  -- Navigation / workflow
  { import = "astrocommunity.motion.harpoon" },
  { import = "astrocommunity.motion.nvim-surround" },
  { import = "astrocommunity.workflow.hardtime-nvim", lazy = false },

  -- Disabled
  -- { import = "astrocommunity.completion.coq_nvim", enabled = false },
  -- { import = "astrocommunity.completion.mini-completion", enabled = false },
  -- { import = "astrocommunity.editing-support.multiple-cursors-nvim", enabled = false },
  -- { import = "astrocommunity.game.leetcode-nvim", enabled = false },
  -- { import = "astrocommunity.git.gitgraph-nvim", enabled = false },
  -- { import = "astrocommunity.keybinding.mini-clue", enabled = false },
  -- { import = "astrocommunity.keybinding.nvcheatsheet-nvim", enabled = false },
  -- { import = "astrocommunity.media.codesnap-nvim", enabled = false },
  -- { import = "astrocommunity.motion.before-nvim", enabled = false },
  -- { import = "astrocommunity.motion.nvim-tree-pairs", enabled = false },
  -- { import = "astrocommunity.note-taking.obsidian-nvim", enabled = false },
  -- { import = "astrocommunity.pack.go", enabled = false },
  -- { import = "astrocommunity.pack.rust", enabled = false },
  -- { import = "astrocommunity.pack.tailwindcss", enabled = false },
  -- { import = "astrocommunity.recipes.vscode-icons", enabled = false },
}
