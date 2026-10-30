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
      },
    },
  },
}
