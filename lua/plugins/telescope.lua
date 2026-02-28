return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.5", -- or latest stable
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local actions = require "telescope.actions"

    require("telescope").setup {
      defaults = {
        mappings = {
          i = {
            ["<C-s>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
          },
          n = {
            ["<C-s>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
          },
        },
      },
    }
  end,
}
