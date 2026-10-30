-- RGBDS (Game Boy assembly) support: filetype detection, build helpers (syntax lives in syntax/rgbasm.vim)
vim.filetype.add {
  extension = {
    rgbasm = "rgbasm",
    rgbinc = "rgbasm",
  },
}

require("rgbasm_ls").setup()

return {
  {
    "AstroNvim/astrocore",
    opts = {
      autocmds = {
        rgbasm = {
          {
            event = "FileType",
            pattern = "rgbasm",
            desc = "RGBDS buffer settings",
            callback = function(args)
              local bo = vim.bo[args.buf]
              bo.commentstring = "; %s"
              bo.expandtab = true
              bo.shiftwidth = 4
              bo.tabstop = 4
              -- build script lives in the project root; errors are parsed into quickfix
              bo.makeprg = "sh first.sh"
              bo.errorformat = table.concat({
                "error: %f(%l):%m",
                "warning: %f(%l):%m",
                "%f(%l):%m",
                "%-G%.%#",
              }, ",")
              vim.keymap.set("n", "<Leader>m", function()
                vim.cmd "silent update"
                vim.cmd "make"
                vim.cmd "cwindow"
              end, { buffer = args.buf, desc = "Build RGBDS project (first.sh)" })
            end,
          },
        },
      },
    },
  },
}
