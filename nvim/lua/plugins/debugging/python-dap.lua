---@type LazySpec
return {
  {
    "mfussenegger/nvim-dap-python",
    optional = true,
    config = function(_, opts) require("config.debugging.python").setup(opts) end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      local maps = opts.mappings

      maps.n["<Leader>dd"] = {
        function() require("config.debugging.python").detach() end,
        desc = "Detach Debugger",
      }
      maps.n["<Leader>dx"] = {
        function() require("dap").set_exception_breakpoints() end,
        desc = "Exception Breakpoints",
      }
      maps.n["<Leader>dl"] = {
        function() require("config.debugging.python").set_logpoint() end,
        desc = "Set Logpoint",
      }
      maps.n["<Leader>dL"] = {
        function() require("config.debugging.python").set_hit_condition() end,
        desc = "Set Hit-count Breakpoint",
      }
      maps.n["<Leader>dv"] = {
        function() require("dap").list_breakpoints() end,
        desc = "List Breakpoints",
      }
      maps.n["<Leader>dt"] = {
        function() require("dap-python").test_method() end,
        desc = "Debug Python Test Method",
      }
      maps.n["<Leader>dT"] = {
        function() require("dap-python").test_class() end,
        desc = "Debug Python Test Class",
      }
    end,
  },
}
