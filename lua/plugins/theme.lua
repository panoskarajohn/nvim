-- Startup colorscheme. Picking a theme with :colorscheme only lasts for the current session,
-- so the one you want on every launch has to be set here.
---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    colorscheme = "astrolight",
  },
}
