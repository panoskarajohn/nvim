return {
  "Isrothy/neominimap.nvim",
  init = function()
    vim.g.neominimap = vim.tbl_deep_extend("force", vim.g.neominimap or {}, {
      diagnostic = {
        enabled = false,
      },
    })
  end,
}
