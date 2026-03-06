return {
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>fW"] = {
            function()
              require("telescope.builtin").live_grep({
                additional_args = function(_)
                  return {
                    "--hidden",
                    "--no-ignore-vcs",
                    -- чтобы не лезть в .git (опционально):
                    "--glob",
                    "!**/.git/*",
                  }
                end,
              })
            end,
            desc = "Live Grep (include hidden files)",
          },
        },
      },
    },
  },
}
