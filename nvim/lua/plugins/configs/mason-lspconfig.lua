return function(_, opts)
  require("mason-lspconfig").setup(opts)
  require("utils").event "MasonLspSetup"
end
