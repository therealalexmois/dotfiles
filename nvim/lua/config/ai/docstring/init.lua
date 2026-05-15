local M = {}

---@param title string
---@param content string
local function open_scratch(title, content)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_name(buf, title)
  vim.api.nvim_set_current_buf(buf)

  local lines = vim.split(content, '\n', { plain = true })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'lua'
end

function M.inspect_visual_selection()
  local extractor = require 'config.ai.docstring.extractor'
  local result, err = extractor.extract_visual_selection(0)

  if result == nil then
    vim.notify(err or 'Failed to extract docstring selection', vim.log.levels.ERROR, {
      title = 'AI Docstring',
    })
    return
  end

  open_scratch('AI Docstring Extractor', vim.inspect(result))
end

function M.setup_commands()
  if vim.fn.exists(':AIDocstringInspect') > 0 then
    return
  end

  vim.api.nvim_create_user_command('AIDocstringInspect', function()
    M.inspect_visual_selection()
  end, {
    desc = 'Inspect Python docstring extractor result for current visual selection',
    range = true,
  })
end

return M
