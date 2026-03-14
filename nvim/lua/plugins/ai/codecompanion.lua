---@type LazySpec
return {
  {
    "olimorris/codecompanion.nvim",
    version = "^19.0.0",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = {
      "CodeCompanion",
      "CodeCompanionActions",
      "CodeCompanionChat",
      "CodeCompanionCmd",
    },
    init = function()
      local ok, wk = pcall(require, "which-key")
      if ok then wk.add {
        { "<leader>A", group = "AI" },
      } end
    end,
    keys = {
      {
        "<leader>AA",
        "<cmd>CodeCompanionActions<cr>",
        desc = "AI action palette",
        mode = { "n", "v" },
      },
      {
        "<leader>Ac",
        "<cmd>CodeCompanionChat Toggle<cr>",
        desc = "AI chat toggle",
        mode = { "n", "v" },
      },
      {
        "<leader>Aq",
        "<cmd>CodeCompanionChat Add<cr>",
        desc = "AI add selection to chat",
        mode = "v",
      },
    },
    opts = {
      adapters = {
        http = {
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
              env = {
                url = "http://127.0.0.1:11434",
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          adapter = {
            name = "ollama",
            model = "mistral-16k",
          },
        },
        inline = {
          adapter = {
            name = "ollama",
            model = "mistral-16k",
          },
        },
        cmd = {
          adapter = {
            name = "ollama",
            model = "mistral-16k",
          },
        },
      },
      prompt_library = {
        markdown = {
          dirs = {
            "~/.dotfiles/llm/prompts/",
          },
        },
      },
      display = {
        action_palette = {
          width = 95,
          height = 10,
          prompt = "Prompt ",
          provider = "snacks",
          opts = {
            show_preset_actions = true,
            show_preset_prompts = false,
            title = "AI actions",
          },
        },
      },
      opts = {
        log_level = "ERROR",
      },
    },
  },
}
