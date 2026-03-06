return {
  "Isrothy/neominimap.nvim",
  init = function()
    vim.g.neominimap = vim.tbl_deep_extend("force", vim.g.neominimap or {}, {
      float = {
        minimap_width = 4,
      },
      split = {
        minimap_width = 4,
      },
      diagnostic = {
        enabled = false,
      },
    })
  end,
}
