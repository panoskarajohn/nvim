return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function() require("harpoon"):setup() end,
  keys = {
    { "<Leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon add file" },
    {
      "<Leader>j",
      function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end,
      desc = "Harpoon menu",
    },
    { "<Leader>k", function() require("harpoon"):list():prev() end, desc = "Harpoon prev" },
    { "<Leader>i", function() require("harpoon"):list():next() end, desc = "Harpoon next" },
    { "<Leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon file 1" },
    { "<Leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon file 2" },
    { "<Leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon file 3" },
    { "<Leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon file 4" },
  },
}
