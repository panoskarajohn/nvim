-- clangd offers "#include <x>" fixes as code actions on symbols that are used without a header.
local function is_include_action(action)
  local title = action.title:lower()
  return title:find("include", 1, true) and not (title:find("remove", 1, true) or title:find("unused", 1, true))
end

local function code_action()
  if vim.bo.filetype == "c" or vim.bo.filetype == "cpp" then
    -- apply = true runs the action directly when only one matches, otherwise it shows a picker
    vim.lsp.buf.code_action { filter = is_include_action, apply = true }
  else
    vim.lsp.buf.code_action()
  end
end

local function switch_source_header()
  if vim.fn.exists(":LspClangdSwitchSourceHeader") == 2 then
    vim.cmd.LspClangdSwitchSourceHeader()
  else
    vim.notify("clangd isn't attached to this buffer", vim.log.levels.WARN)
  end
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      n = {
        -- C/C++: add the missing include under the cursor. Other filetypes: normal code action menu
        -- (the full menu is always on <Leader>la)
        ["<Leader>;"] = { code_action, desc = "Add include / code actions" },
        -- C/C++: jump between .h and .cpp. clangd knows which files belong together, and
        -- nvim-lspconfig creates this command in every buffer clangd attaches to.
        ["<Leader>s"] = { switch_source_header, desc = "Switch between header and source" },
      },
    },
  },
}
