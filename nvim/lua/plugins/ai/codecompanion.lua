---@type LazySpec
return {
  {
    'olimorris/codecompanion.nvim',
    version = '^19.0.0',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    cmd = {
      'CodeCompanion',
      'CodeCompanionActions',
      'CodeCompanionChat',
      'CodeCompanionCmd',
    },
    init = function()
      local profiles = require('config.ai.codecompanion_profiles')

      profiles.setup_commands()
      profiles.notify_preflight()

      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add({
          { '<leader>A', group = 'AI' },
        })
      end
    end,
    keys = {
      {
        '<leader>AA',
        '<cmd>CodeCompanionActions<cr>',
        desc = 'AI action palette',
        mode = { 'n', 'v' },
      },
      {
        '<leader>Ac',
        '<cmd>CodeCompanionChat Toggle<cr>',
        desc = 'AI chat toggle',
        mode = { 'n', 'v' },
      },
      {
        '<leader>Aq',
        '<cmd>CodeCompanionChat Add<cr>',
        desc = 'AI add selection to chat',
        mode = 'v',
      },
    },
    opts = function()
      local profiles = require('config.ai.codecompanion_profiles')
      local interaction_adapter = profiles.get_interaction_adapter()

      return {
        adapters = {
          http = {
            opts = profiles.get_http_opts(),
            ollama = function()
              return require('codecompanion.adapters').extend('ollama', {
                env = {
                  url = 'http://127.0.0.1:11434',
                },
                schema = {
                  model = {
                    default = profiles.get_home_model(),
                  },
                },
              })
            end,
            work_proxy = function()
              return require('codecompanion.adapters').extend('openai_compatible', {
                env = {
                  url = 'NVIM_AI_WORK_URL',
                  api_key = 'NVIM_AI_WORK_API_KEY',
                  chat_url = function()
                    return profiles.get_work_chat_url()
                  end,
                },
                headers = {
                  ['Content-Type'] = 'application/json',
                  ['Authorization'] = 'Bearer ${api_key}',
                },
                schema = {
                  model = {
                    default = profiles.get_work_model(),
                  },
                },
              })
            end,
          },
        },
        interactions = {
          chat = {
            adapter = interaction_adapter,
          },
          inline = {
            adapter = interaction_adapter,
          },
          cmd = {
            adapter = interaction_adapter,
          },
        },
        prompt_library = {
          markdown = {
            dirs = {
              '~/.dotfiles/llm/prompts/',
            },
          },
        },
        display = {
          action_palette = {
            width = 95,
            height = 10,
            prompt = 'Prompt ',
            provider = 'snacks',
            opts = {
              show_preset_actions = true,
              show_preset_prompts = false,
              title = 'AI actions',
            },
          },
        },
        opts = {
          log_level = 'ERROR',
        },
      }
    end,
  },
}
