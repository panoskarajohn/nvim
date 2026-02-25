
-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

require('lspconfig').omnisharp.setup({
  cmd = {
    "omnisharp",
    "--languageserver",
    "--hostPID", tostring(vim.fn.getpid()),
    "--RoslynExtensionsOptions:enableAnalyzersSupport=true",
    "FormattingOptions:EnableEditorConfigSupport=true",
    "CodeLensOptions:Enabled=true"
  },
  on_attach = function(client, bufnr)
    if client.server_capabilities.codeLensProvider then
      vim.api.nvim_create_autocmd({"BufEnter", "InsertLeave"}, {
        buffer = bufnr,
        callback = function()
          vim.lsp.codelens.refresh()
        end
      })
    end
  end,
  -- ... other config options ...
})

require('lspconfig').clangd.setup({
  cmd = {
    "clangd",
    "--background-index",                 -- keep a background index of the project
    "--clang-tidy",                       -- run clang-tidy diagnostics
    "--completion-style=detailed",        -- richer completion items
    "--header-insertion=never",           -- don't auto-insert #include lines
    "--fallback-style=LLVM"               -- formatting fallback style
  },
  on_attach = function(client, bufnr)
    -- refresh CodeLens like in your omnisharp config
    if client.server_capabilities.codeLensProvider then
      vim.api.nvim_create_autocmd({"BufEnter", "InsertLeave"}, {
        buffer = bufnr,
        callback = function()
          vim.lsp.codelens.refresh()
        end
      })
    end
  end,
  -- add completion capabilities if you use nvim-cmp
  -- root detection: prefer compile_commands.json or .git
  root_dir = require('lspconfig.util').root_pattern('compile_commands.json', 'compile_flags.txt', '.git'),
  -- other clangd-specific options can go here (e.g., handlers, init_options)
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = {"*.cs", "*.c", "*.cpp", "*.h", "*.cc", "*.cxx", "*.hpp", "*.hh", "*.hxx", "*.js", "*.ts", "*.jsx", "*.tsx", "*.lua", "*.py", "*.go", "*.rs"},
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- Enforce LF line endings in Neovim
vim.opt.fileformat = "unix"
vim.opt.fileformats = { "unix", "dos" } -- read DOS if present, write as UNIX

-- Force LF on every save for all buffers
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(ev)
    vim.bo[ev.buf].fileformat = "unix"
  end,
})

-- Optional: command to convert current buffer to LF and strip stray CRs, then write
vim.api.nvim_create_user_command("ToLF", function()
  vim.cmd([[%s/\r$//e]])
  vim.bo.fileformat = "unix"
  vim.cmd("write")
end, {})

vim.keymap.set(
  'n',
  '<leader>o',
  '<cmd>ClangdSwitchSourceHeader<CR>',
  { silent = true }
)

vim.cmd.colorscheme("catppuccin-frappe")
vim.opt.guifont = "FiraCode Nerd Font:h13"
