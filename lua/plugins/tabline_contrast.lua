return {
  {
    "AstroNvim/astroui",
    opts = function(_, opts)
      opts.status = opts.status or {}
      opts.status.colors = vim.tbl_extend("force", opts.status.colors or {}, {
        tabline_bg = "#182334",
        buffer_bg = "#182334",
        buffer_fg = "#8FA9CF",
        buffer_visible_bg = "#22324A",
        buffer_visible_fg = "#D6E4FA",
        buffer_active_bg = "#3B82F6",
        buffer_active_fg = "#F8FBFF",
        tab_bg = "#22324A",
        tab_fg = "#9DB7DD",
        tab_active_bg = "#3B82F6",
        tab_active_fg = "#F8FBFF",
      })
    end,
  },
}
