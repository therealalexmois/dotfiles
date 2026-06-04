-- lua/plugins/ui/smart-splits.lua
-- Resolve the <C-Up>/<C-Down> clash between vim-visual-multi (add cursor) and
-- smart-splits (resize split). Keep multicursor on the vertical arrows and move
-- vertical split resize to <C-S-Up>/<C-S-Down>. Horizontal resize stays on
-- <C-Left>/<C-Right>.
return {
  "mrjones2014/smart-splits.nvim",
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        -- Reclaim <C-Up>/<C-Down> for vim-visual-multi (add cursor above/below),
        -- overriding the smart-splits resize bound on the same keys. Set the same
        -- commands the vim-visual-multi pack uses, with canonical key casing, so a
        -- single mapping wins instead of a casing-conflicting pair. Plain `= false`
        -- cannot be used here: AstroCore deletes by normalized keycode and would
        -- also remove the pack's lowercase <C-up>/<C-down> add-cursor mappings.
        maps.n["<C-Up>"] = { "<C-u>call vm#commands#add_cursor_up(0, v:count1)<cr>", desc = "Add cursor above" }
        maps.n["<C-Down>"] = { "<C-u>call vm#commands#add_cursor_down(0, v:count1)<cr>", desc = "Add cursor below" }
        -- Move vertical split resize to Ctrl+Shift+Up/Down.
        maps.n["<C-S-Up>"] = { function() require("smart-splits").resize_up() end, desc = "Resize split up" }
        maps.n["<C-S-Down>"] = { function() require("smart-splits").resize_down() end, desc = "Resize split down" }
      end,
    },
  },
}
