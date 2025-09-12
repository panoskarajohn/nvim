return {
  "ray-x/lsp_signature.nvim",
  config = function()
    require("lsp_signature").setup({
      handler_opts = { border = "rounded" },
      always_trigger = true, -- always show signature help when inside function call
      select_signature_key = "<C-j>", -- cycle forward
      move_cursor_key = "<C-k>",      -- cycle backward
    })
  end,
}
