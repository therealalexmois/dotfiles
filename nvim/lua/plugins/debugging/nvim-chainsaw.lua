---@type LazySpec
return {
  {
    'chrisgrieser/nvim-chainsaw',
    event = 'User AstroFile',
    init = function()
      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add({
          { '<leader>L', group = 'Log' },
        })
      end
    end,
    keys = {
      {
        '<leader>Lv',
        function() require('chainsaw').variableLog() end,
        desc = 'Variable log',
      },
      {
        '<leader>Lo',
        function() require('chainsaw').objectLog() end,
        desc = 'Object log',
      },
      {
        '<leader>Ly',
        function() require('chainsaw').typeLog() end,
        desc = 'Type log',
      },
      {
        '<leader>La',
        function() require('chainsaw').assertLog() end,
        desc = 'Assert log',
      },
      {
        '<leader>Le',
        function() require('chainsaw').emojiLog() end,
        desc = 'Emoji log',
      },
      {
        '<leader>Lm',
        function() require('chainsaw').messageLog() end,
        desc = 'Message log',
      },
      {
        '<leader>Lt',
        function() require('chainsaw').timeLog() end,
        desc = 'Time log',
      },
      {
        '<leader>Ld',
        function() require('chainsaw').debugLog() end,
        desc = 'Debug log',
      },
      {
        '<leader>Ls',
        function() require('chainsaw').stacktraceLog() end,
        desc = 'Stacktrace log',
      },
      {
        '<leader>Lr',
        function() require('chainsaw').removeLogs() end,
        desc = 'Remove logs',
      },
    },
  },
}
