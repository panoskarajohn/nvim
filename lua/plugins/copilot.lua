return {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            -- M is Option key on Mac, need to set it to Esc+ in iterm2
           accept = "<M-y>",
           next = "<M-n>",
           prev = "<M-p>",
           dismiss = "<M-e>",
         },
        },
        panel = { enabled = true },
        filetypes = {
          lua = true,
          cpp = true,
          csharp = true,
          cs = true,
          ["*"] = false,
        },
      })
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    dependencies = { "zbirenbaum/copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end,
  },
}
