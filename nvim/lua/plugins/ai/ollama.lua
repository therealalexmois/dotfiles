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
          { '<leader>A', group = 'AI' },
        })
      end
    end,
    keys = {
      {
        '<leader>Aa',
        function() require('ollama').prompt() end,
        desc = 'AI prompt',
        mode = { 'n', 'v' },
      },
      {
        '<leader>AG',
        function() require('ollama').prompt('Generate_Code') end,
        desc = 'AI generate code',
        mode = { 'n', 'v' },
      },
      {
        '<leader>Am',
        '<cmd>OllamaModel<cr>',
        desc = 'AI select model',
      },
      {
        '<leader>As',
        '<cmd>OllamaServe<cr>',
        desc = 'AI serve start',
      },
      {
        '<leader>AS',
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
