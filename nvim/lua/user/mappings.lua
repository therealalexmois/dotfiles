return {
  n = {
    ["<leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
    ["<leader>bD"] = {
      function()
        require("utils.status").heirline.buffer_picker(function(bufnr) require("utils.buffer").close(bufnr) end)
      end,
      desc = "Pick to close",
    },
  }
}
