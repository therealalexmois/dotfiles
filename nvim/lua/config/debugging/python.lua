local M = {}

local ERROR_MESSAGE =
  "Python DAP is unavailable: Mason executable debugpy-adapter was not found. Run :MasonToolsInstall."

function M.resolve_adapter(exepath)
  local path = (exepath or vim.fn.exepath) "debugpy-adapter"
  if not path or path == "" then return nil, ERROR_MESSAGE end
  return path, nil
end

function M.setup(opts, dependencies)
  dependencies = dependencies or {}
  local path, err = M.resolve_adapter(dependencies.exepath)

  if not path then
    local notify = dependencies.notify or vim.notify
    local schedule = dependencies.schedule or vim.schedule
    schedule(function() notify(err, vim.log.levels.ERROR, { title = "Python DAP" }) end)
    return false
  end

  local dap_python = dependencies.dap_python or require "dap-python"
  dap_python.setup(path, opts or {})
  return true
end

function M.detach()
  local dap = require "dap"
  dap.disconnect({ terminateDebuggee = false }, function() dap.close() end)
end

local function persist_current_buffer_breakpoints()
  local ok, persistence = pcall(require, "persistent-breakpoints.api")
  if ok then persistence.breakpoints_changed_in_current_buffer() end
end

function M.set_logpoint()
  vim.ui.input({ prompt = "Log point message: " }, function(message)
    message = vim.trim(message or "")
    if message == "" then return end
    require("dap").set_breakpoint(nil, nil, message)
    persist_current_buffer_breakpoints()
  end)
end

function M.set_hit_condition()
  vim.ui.input({ prompt = "Break after hit count: " }, function(count)
    count = vim.trim(count or "")
    if count == "" then return end
    require("dap").set_breakpoint(nil, count)
    persist_current_buffer_breakpoints()
  end)
end

return M
