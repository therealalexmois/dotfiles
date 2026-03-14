local M = {}

local DEFAULT_HOME_PROFILE = 'home_local'
local DEFAULT_WORK_PROFILE = 'work_proxy'
local DEFAULT_HOME_MODEL = 'mistral-16k'
local DEFAULT_WORK_CHAT_URL = '/v1/chat/completions'

local REQUIRED_WORK_ENV = {
  'NVIM_AI_WORK_URL',
  'NVIM_AI_WORK_API_KEY',
  'NVIM_AI_WORK_MODEL',
}

local function is_true(value)
  return value == '1' or value == 'true' or value == 'yes'
end

function M.get_active_profile()
  local profile = (vim.env.NVIM_AI_PROFILE or ''):lower()

  if profile == '' then return DEFAULT_HOME_PROFILE end
  if profile == 'home' then return DEFAULT_HOME_PROFILE end
  if profile == 'work' then return DEFAULT_WORK_PROFILE end

  return profile
end

function M.is_work_proxy()
  return M.get_active_profile() == DEFAULT_WORK_PROFILE
end

function M.get_home_model()
  return DEFAULT_HOME_MODEL
end

function M.get_work_model()
  return vim.env.NVIM_AI_WORK_MODEL or ''
end

function M.get_work_chat_url()
  return vim.env.NVIM_AI_WORK_CHAT_URL or DEFAULT_WORK_CHAT_URL
end

function M.get_http_opts()
  local opts = {
    show_presets = false,
  }

  if not M.is_work_proxy() then return opts end

  if vim.env.NVIM_AI_WORK_PROXY and vim.env.NVIM_AI_WORK_PROXY ~= '' then
    opts.proxy = vim.env.NVIM_AI_WORK_PROXY
  end

  opts.allow_insecure = is_true(vim.env.NVIM_AI_WORK_ALLOW_INSECURE)

  return opts
end

function M.get_interaction_adapter()
  if M.is_work_proxy() then return DEFAULT_WORK_PROFILE end

  return {
    name = 'ollama',
    model = M.get_home_model(),
  }
end

function M.validate_work_proxy()
  if not M.is_work_proxy() then
    return {
      ok = true,
      profile = DEFAULT_HOME_PROFILE,
      message = ('AI profile: %s (ollama, model=%s)'):format(DEFAULT_HOME_PROFILE, M.get_home_model()),
      level = vim.log.levels.INFO,
    }
  end

  local missing = {}

  for _, name in ipairs(REQUIRED_WORK_ENV) do
    if not vim.env[name] or vim.env[name] == '' then table.insert(missing, name) end
  end

  if #missing > 0 then
    return {
      ok = false,
      profile = DEFAULT_WORK_PROFILE,
      message = ('AI profile "%s" is not ready. Missing ENV: %s'):format(DEFAULT_WORK_PROFILE, table.concat(missing, ', ')),
      level = vim.log.levels.ERROR,
    }
  end

  return {
    ok = true,
    profile = DEFAULT_WORK_PROFILE,
    message = ('AI profile: %s (ready, model=%s)'):format(DEFAULT_WORK_PROFILE, M.get_work_model()),
    level = vim.log.levels.INFO,
  }
end

function M.notify_preflight()
  local status = M.validate_work_proxy()

  if status.profile ~= DEFAULT_WORK_PROFILE then return end

  vim.schedule(function()
    vim.notify(status.message, status.level, { title = 'AI profile' })
  end)
end

function M.setup_commands()
  if vim.fn.exists(':AIProfileStatus') > 0 then return end

  vim.api.nvim_create_user_command('AIProfileStatus', function()
    local status = M.validate_work_proxy()
    vim.notify(status.message, status.level, { title = 'AI profile' })
  end, {
    desc = 'Show active AI profile status',
  })
end

return M
