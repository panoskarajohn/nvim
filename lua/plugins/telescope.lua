return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.5", -- or latest stable
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("telescope").setup()
  end,
}
