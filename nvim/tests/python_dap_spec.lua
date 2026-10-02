vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/nvim")

local python_dap = require "config.debugging.python"

local function eq(actual, expected, message)
  assert(vim.deep_equal(actual, expected), message or vim.inspect { actual = actual, expected = expected })
end

local resolved, resolve_err = python_dap.resolve_adapter(function(name)
  eq(name, "debugpy-adapter")
  return "/tmp/mason/bin/debugpy-adapter"
end)
eq(resolved, "/tmp/mason/bin/debugpy-adapter")
eq(resolve_err, nil)

local missing, missing_err = python_dap.resolve_adapter(function() return "" end)
eq(missing, nil)
assert(missing_err:find("debugpy%-adapter", 1, false))

local calls = {}
local notifications = {}
local ok = python_dap.setup({ console = "integratedTerminal" }, {
  exepath = function() return "/tmp/mason/bin/debugpy-adapter" end,
  dap_python = {
    setup = function(path, opts) table.insert(calls, { path = path, opts = opts }) end,
  },
  notify = function(message, level) table.insert(notifications, { message = message, level = level }) end,
  schedule = function(callback) callback() end,
})
eq(ok, true)
eq(calls, {
  {
    path = "/tmp/mason/bin/debugpy-adapter",
    opts = { console = "integratedTerminal" },
  },
})
eq(#notifications, 0)

local missing_ok = python_dap.setup({}, {
  exepath = function() return "" end,
  dap_python = { setup = function() error "setup must not run" end },
  notify = function(message, level) table.insert(notifications, { message = message, level = level }) end,
  schedule = function(callback) callback() end,
})
eq(missing_ok, false)
assert(notifications[#notifications].message:find("debugpy%-adapter", 1, false))

print "python_dap_spec: ok"
