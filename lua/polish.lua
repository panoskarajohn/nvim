
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

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.cs",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})
