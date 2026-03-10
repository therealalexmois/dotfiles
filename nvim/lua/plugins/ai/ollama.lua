---@type LazySpec
return {
  {
    'nomnivore/ollama.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    cmd = { 'Ollama', 'OllamaModel', 'OllamaServe', 'OllamaServeStop' },
    init = function()
      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add({
          { '<leader>a', group = 'AI' },
        })
      end
    end,
    keys = {
      {
        '<leader>aa',
        function() require('ollama').prompt() end,
        desc = 'AI prompt',
        mode = { 'n', 'v' },
      },
      {
        '<leader>aG',
        function() require('ollama').prompt('Generate_Code') end,
        desc = 'AI generate code',
        mode = { 'n', 'v' },
      },
      {
        '<leader>am',
        '<cmd>OllamaModel<cr>',
        desc = 'AI select model',
      },
      {
        '<leader>as',
        '<cmd>OllamaServe<cr>',
        desc = 'AI serve start',
      },
      {
        '<leader>aS',
        '<cmd>OllamaServeStop<cr>',
        desc = 'AI serve stop',
      },
    },
    ---@type Ollama.Config
    opts = {
      model = 'mistral',
      url = 'http://127.0.0.1:11434',
      serve = {
        on_start = false,
        command = 'ollama',
        args = { 'serve' },
        stop_command = 'pkill',
        stop_args = { '-SIGTERM', 'ollama' },
      },
    },
  },
}
