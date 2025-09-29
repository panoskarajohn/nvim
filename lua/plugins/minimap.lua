if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  "echasnovski/mini.map",
  version = false, -- use latest
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  event = "VeryLazy",
  opts = function()
    local m = require("mini.map")

    -- Build integrations list safely (older versions may miss some)
    local integrations = {}
    local gi = m.gen_integration or {}

    if gi.builtin_search then table.insert(integrations, gi.builtin_search()) end
    if gi.diagnostic then table.insert(integrations, gi.diagnostic()) end
    if gi.treesitter then
      table.insert(integrations, gi.treesitter())
    end

    return {
      -- Try simpler symbols to avoid “?” glyphs in some fonts/terminals
      symbols = {
        -- Use block encoding but smaller density to reduce exotic glyphs
        encode = m.gen_encode_symbols.block("2x1"),
      },
      window = {
        side = "right",
        width = 12,
        winblend = 15,
        show_integration_count = false,
      },
      integrations = integrations,
    }
  end,
  config = function(_, opts)
    local m = require("mini.map")
    m.setup(opts)

    -- Auto-open only for normal file buffers with some content
    vim.api.nvim_create_autocmd("BufReadPost", {
      callback = function(args)
        local bt = vim.bo[args.buf].buftype
        if bt ~= "" then return end
        if vim.fn.line("$") < 30 then return end
        -- Defer to ensure proper layout after buffer loads
        vim.schedule(function()
          pcall(m.open)
        end)
      end,
    })

    -- Optional keymaps
    vim.keymap.set("n", "<leader>mm", function() pcall(m.toggle) end, { desc = "MiniMap Toggle" })
    vim.keymap.set("n", "<leader>mo", function() pcall(m.open) end,   { desc = "MiniMap Open" })
    vim.keymap.set("n", "<leader>mc", function() pcall(m.close) end,  { desc = "MiniMap Close" })
    vim.keymap.set("n", "<leader>mr", function() pcall(m.refresh) end,{ desc = "MiniMap Refresh" })
  end,
}
