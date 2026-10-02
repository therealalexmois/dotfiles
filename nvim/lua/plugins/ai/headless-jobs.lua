--- Thin command and scratch-buffer surface for isolated background AI jobs.
---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    init = function() require("config.ai.headless_jobs").setup() end,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<leader>Ar"] = {
        "<cmd>AIJobStart<cr>",
        desc = "AI job start",
      }
      opts.mappings.n["<leader>Aj"] = {
        "<cmd>AIJobList<cr>",
        desc = "AI job list",
      }
      opts.mappings.n["<leader>Ao"] = {
        "<cmd>AIJobOpen<cr>",
        desc = "AI job open output",
      }
      opts.mappings.n["<leader>Ax"] = {
        "<cmd>AIJobCancel<cr>",
        desc = "AI job cancel",
      }
      return opts
    end,
  },
}
