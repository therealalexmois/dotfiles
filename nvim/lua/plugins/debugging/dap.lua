-- Дополнения к настройке nvim-dap из AstroNvim: подписи панелей DAP UI,
-- быстрые прыжки между ними и маппинги, которых нет в дефолте.

-- Панели боковой раскладки. REPL и Console намеренно не трогаем: dapui рисует
-- в их winbar свои кнопки управления, подпись их затрет.
local sidebar_titles = {
  dapui_scopes = "Scopes",
  dapui_breakpoints = "Breakpoints",
  dapui_stacks = "Stacks",
  dapui_watches = "Watches",
}

--- Проставляет winbar-подписи всем открытым панелям DAP UI.
local function label_windows()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local title = sidebar_titles[vim.bo[buf].filetype]

    if title then vim.api.nvim_set_option_value("winbar", "%#Title# " .. title, { scope = "local", win = win }) end
  end
end

--- Возвращает функцию перехода в панель DAP UI по filetype буфера.
---@param filetype string filetype панели, например `dapui_watches`
---@param element string имя элемента dapui для fallback во всплывающее окно
local function goto_panel(filetype, element)
  return function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == filetype then
        vim.api.nvim_set_current_win(win)
        return
      end
    end

    require("dapui").float_element(element, { enter = true })
  end
end

--- Маппинги, которые имеют смысл только при открытом DAP UI.
--- Регистрируются на старте сессии и снимаются на ее завершении, поэтому не
--- засоряют which-key, пока отладчик не запущен.
local session_mappings = {
  ["<Leader>d1"] = { goto_panel("dapui_scopes", "scopes"), "Go To Scopes" },
  ["<Leader>d2"] = { goto_panel("dapui_breakpoints", "breakpoints"), "Go To Breakpoints" },
  ["<Leader>d3"] = { goto_panel("dapui_stacks", "stacks"), "Go To Stacks" },
  ["<Leader>d4"] = { goto_panel("dapui_watches", "watches"), "Go To Watches" },
  ["<Leader>d5"] = { goto_panel("dap-repl", "repl"), "Go To REPL" },
  ["<Leader>d6"] = { goto_panel("dapui_console", "console"), "Go To Console" },
  ["<Leader>dw"] = {
    function()
      vim.ui.input({ prompt = "Watch: " }, function(expr)
        if expr then require("dapui").elements.watches.add(expr) end
      end)
    end,
    "Add Watch Expression",
  },
  ["<Leader>dU"] = {
    function() require("dapui").open { reset = true } end,
    "Reset Debugger UI Layout",
  },
}

local function set_session_mappings()
  for lhs, mapping in pairs(session_mappings) do
    vim.keymap.set("n", lhs, mapping[1], { desc = mapping[2] })
  end
end

local function del_session_mappings()
  for lhs in pairs(session_mappings) do
    pcall(vim.keymap.del, "n", lhs)
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    optional = true,
    specs = {
      {
        "AstroNvim/astrocore",
        opts = function(_, opts)
          local maps = opts.mappings

          maps.n["<Leader>dL"] = {
            function() require("dap").list_breakpoints(true) end,
            desc = "List Breakpoints (quickfix)",
          }
        end,
      },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    optional = true,
    opts = function(_, opts)
      local dap = require "dap"

      dap.listeners.after.event_initialized.astro_dap_session_mappings = set_session_mappings
      dap.listeners.before.event_terminated.astro_dap_session_mappings = del_session_mappings
      dap.listeners.before.event_exited.astro_dap_session_mappings = del_session_mappings

      return opts
    end,
    specs = {
      {
        "AstroNvim/astrocore",
        opts = function(_, opts)
          if not opts.autocmds then opts.autocmds = {} end

          opts.autocmds.dapui_panel_labels = {
            {
              event = { "FileType", "BufWinEnter", "WinNew" },
              desc = "Подписать панели DAP UI в winbar",
              callback = function() vim.schedule(label_windows) end,
            },
          }
        end,
      },
    },
  },
}
