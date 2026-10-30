-- Tiny in-process language server for RGBDS (rgbasm) files.
-- Features: completion (SM83 mnemonics, directives, project symbols), hover,
-- go-to-definition, document symbols and diagnostics from `rgbasm` on save.
local M = {}

local K = vim.lsp.protocol.CompletionItemKind

local instructions = {
  "adc", "add", "and", "bit", "call", "ccf", "cp", "cpl", "daa", "dec", "di", "ei", "halt", "inc",
  "jp", "jr", "ld", "ldh", "nop", "or", "pop", "push", "res", "ret", "reti", "rl", "rla", "rlc",
  "rlca", "rr", "rra", "rrc", "rrca", "rst", "sbc", "scf", "set", "sla", "sra", "srl", "stop",
  "sub", "swap", "xor",
}

local directives = {
  "align", "assert", "break", "charmap", "db", "dl", "ds", "dw", "elif", "else", "endc", "endl",
  "endm", "endr", "endsection", "export", "fail", "fatal", "for", "if", "include", "incbin", "load",
  "macro", "newcharmap", "nextu", "opt", "popc", "popo", "pops", "printt", "println", "print",
  "purge", "pushc", "pusho", "pushs", "rb", "rept", "rw", "rsreset", "rsset", "section", "setcharmap",
  "shift", "static_assert", "union", "warn", "def", "redef", "equ", "equs", "set", "const",
  "rom0", "romx", "vram", "sram", "wram0", "wramx", "oam", "hram",
}

local functions = {
  "bank", "high", "low", "sizeof", "startof", "strlen", "strcat", "strsub", "strin", "strrin",
  "strupr", "strlwr", "strrpl", "strfmt", "charlen", "charsub", "charcmp", "div", "mul", "fmod",
  "pow", "log", "round", "ceil", "floor", "sin", "cos", "tan", "asin", "acos", "atan", "atan2",
  "isconst", "def", "bytelen", "bytesub", "readfile",
}

local registers = { "a", "b", "c", "d", "e", "h", "l", "af", "bc", "de", "hl", "sp", "hli", "hld", "nz", "nc", "z" }

local docs = {
  ld = "Load: `ld dst, src`. Flags unaffected.",
  ldh = "Load to/from high RAM ($FF00-$FFFF): `ldh [n8], a` / `ldh a, [n8]`.",
  jp = "Jump to address. `jp [cc,] n16` or `jp hl`.",
  jr = "Relative jump (-128..127). `jr [cc,] label`.",
  call = "Push return address and jump. `call [cc,] n16`.",
  ret = "Pop return address and jump. `ret [cc]`.",
  reti = "Return and enable interrupts.",
  rst = "Call fixed address ($00,$08,..$38).",
  push = "Push 16-bit register pair.",
  pop = "Pop 16-bit register pair.",
  inc = "Increment register or `[hl]`. 8-bit sets Z,N,H.",
  dec = "Decrement register or `[hl]`. 8-bit sets Z,N,H.",
  add = "Add. `add a, r8/n8/[hl]`, `add hl, r16`, `add sp, e8`.",
  adc = "Add with carry into `a`.",
  sub = "Subtract from `a`.",
  sbc = "Subtract with carry from `a`.",
  cp = "Compare with `a` (subtract, discard result; sets flags).",
  ["and"] = "Bitwise AND into `a`.",
  xor = "Bitwise XOR into `a`. `xor a` zeroes `a`.",
  ["or"] = "Bitwise OR into `a`.",
  bit = "Test bit: `bit u3, r8`. Sets Z if bit is 0.",
  res = "Reset bit: `res u3, r8`.",
  set = "Set bit: `set u3, r8`.",
  swap = "Swap nibbles of r8.",
  halt = "Halt CPU until an interrupt.",
  stop = "Enter very-low-power mode.",
  di = "Disable interrupts.",
  ei = "Enable interrupts (after next instruction).",
  section = '`section "name", rom0[$addr]` — place following code/data.',
  macro = "`macro name ... endm` — define a macro; arguments are `\\1`..`\\9`.",
  def = "`def NAME equ value` — define a constant.",
  ds = "Reserve space: `ds n[, fill]`.",
  db = "Emit bytes.",
  dw = "Emit 16-bit words.",
  include = '`include "file"` — textually include a file.',
  incbin = '`incbin "file"` — include raw binary.',
}

local function keyword_items()
  local items = {}
  local function add(list, kind, detail)
    for _, w in ipairs(list) do
      items[#items + 1] = {
        label = w,
        kind = kind,
        detail = detail,
        documentation = docs[w] and { kind = "markdown", value = docs[w] } or nil,
      }
    end
  end
  add(instructions, K.Keyword, "instruction")
  add(directives, K.Keyword, "directive")
  add(functions, K.Function, "function")
  add(registers, K.Variable, "register/condition")
  return items
end

local keyword_cache = keyword_items()

-- Symbol definitions -------------------------------------------------------

local function project_files(root)
  return vim.fn.globpath(root, "*.rgb*", false, true)
end

local function read_lines(path)
  local bufnr = vim.fn.bufnr(path)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and lines or {}
end

-- Returns list of { name, kind, file, line, col, text }
local function scan_symbols(root)
  local syms = {}
  for _, file in ipairs(project_files(root)) do
    local lines = read_lines(file)
    local global = nil
    for i, text in ipairs(lines) do
      local function push(name, kind)
        syms[#syms + 1] = { name = name, kind = kind, file = file, line = i - 1, text = text }
      end
      local lower = text:lower()
      local name = text:match "^%s*([%a_][%w_#@]*)::?"
      if name then
        global = name
        push(name, K.Function)
      else
        local local_name = text:match "^%s*(%.[%a_][%w_#@]*)::?"
        if local_name then
          push(global and (global .. local_name) or local_name, K.Field)
          push(local_name, K.Field)
        end
      end
      local def = lower:match "^%s*def%s+([%w_#@]+)%s+" or lower:match "^%s*redef%s+([%w_#@]+)%s+"
      if def then
        -- keep original casing
        local orig = text:match "^%s*[%a]+%s+([%w_#@]+)"
        push(orig or def, K.Constant)
      end
      local plain_equ = text:match "^%s*([%a_][%w_#@]*)%s+[eE][qQ][uU]%s"
      if plain_equ then push(plain_equ, K.Constant) end
      local mac = text:match "^%s*[mM][aA][cC][rR][oO]%s+([%w_#@]+)"
      if mac then push(mac, K.Snippet) end
    end
  end
  return syms
end

local function word_at(line, col)
  local s, e = col, col
  while s > 0 and line:sub(s, s):match "[%w_#@.]" do s = s - 1 end
  while e < #line and line:sub(e + 1, e + 1):match "[%w_#@.]" do e = e + 1 end
  return line:sub(s + 1, e)
end

-- Diagnostics --------------------------------------------------------------

local function parse_diagnostics(output, file)
  local diags = {}
  local current
  local function flush()
    if current and current.line then diags[#diags + 1] = current end
    current = nil
  end
  for _, l in ipairs(vim.split(output, "\n", { plain = true })) do
    local sev, msg = l:match "^(%a+): (.*)$"
    if sev == "error" or sev == "warning" or sev == "fatal error" then
      flush()
      current = {
        severity = sev == "warning" and vim.diagnostic.severity.WARN or vim.diagnostic.severity.ERROR,
        message = msg,
        source = "rgbasm",
      }
    else
      local f, n = l:match "^%s+at (.-)%((%d+)%)"
      if f and current and not current.line and vim.fs.normalize(f) == vim.fs.normalize(file) then
        current.line = tonumber(n) - 1
      end
    end
  end
  flush()
  return diags
end

-- Server -------------------------------------------------------------------

local function server(dispatchers)
  local closing = false
  local root = vim.uv.cwd()
  local id = 0

  local function publish(uri, diagnostics)
    local out = {}
    for _, d in ipairs(diagnostics) do
      out[#out + 1] = {
        severity = d.severity,
        message = d.message,
        source = d.source,
        range = {
          start = { line = d.line, character = 0 },
          ["end"] = { line = d.line, character = 1000 },
        },
      }
    end
    dispatchers.notification("textDocument/publishDiagnostics", { uri = uri, diagnostics = out })
  end

  local function run_diagnostics(uri)
    local file = vim.uri_to_fname(uri)
    local rel = vim.fs.relpath(root, file) or file
    vim.system(
      { "rgbasm", "-Weverything", "-o", "/dev/null", rel },
      { cwd = root, text = true },
      vim.schedule_wrap(function(res)
        if closing then return end
        publish(uri, parse_diagnostics((res.stderr or "") .. (res.stdout or ""), rel))
      end)
    )
  end

  local handlers = {}

  handlers["initialize"] = function(params)
    if params.rootUri then root = vim.uri_to_fname(params.rootUri) end
    return {
      capabilities = {
        textDocumentSync = { openClose = true, change = 0, save = true },
        completionProvider = { triggerCharacters = {}, resolveProvider = false },
        hoverProvider = true,
        definitionProvider = true,
        documentSymbolProvider = true,
      },
      serverInfo = { name = "rgbasm_ls" },
    }
  end

  handlers["shutdown"] = function() return vim.NIL end

  handlers["textDocument/completion"] = function()
    local items = vim.list_extend({}, keyword_cache)
    local seen = {}
    for _, s in ipairs(scan_symbols(root)) do
      if not seen[s.name] then
        seen[s.name] = true
        items[#items + 1] = {
          label = s.name,
          kind = s.kind,
          detail = vim.fs.basename(s.file) .. ":" .. (s.line + 1),
          documentation = { kind = "markdown", value = "```rgbasm\n" .. vim.trim(s.text) .. "\n```" },
        }
      end
    end
    return { isIncomplete = false, items = items }
  end

  local function symbol_under_cursor(params)
    local file = vim.uri_to_fname(params.textDocument.uri)
    local line = read_lines(file)[params.position.line + 1] or ""
    local word = word_at(line, params.position.character)
    if word == "" then return nil end
    for _, s in ipairs(scan_symbols(root)) do
      if s.name:lower() == word:lower() then return s end
    end
    return nil, word
  end

  handlers["textDocument/definition"] = function(params)
    local s = symbol_under_cursor(params)
    if not s then return vim.NIL end
    return {
      uri = vim.uri_from_fname(s.file),
      range = {
        start = { line = s.line, character = 0 },
        ["end"] = { line = s.line, character = #s.text },
      },
    }
  end

  handlers["textDocument/hover"] = function(params)
    local s, word = symbol_under_cursor(params)
    if s then
      return {
        contents = {
          kind = "markdown",
          value = ("```rgbasm\n%s\n```\n%s:%d"):format(vim.trim(s.text), vim.fs.basename(s.file), s.line + 1),
        },
      }
    end
    if word and docs[word:lower()] then
      return { contents = { kind = "markdown", value = docs[word:lower()] } }
    end
    return vim.NIL
  end

  handlers["textDocument/documentSymbol"] = function(params)
    local file = vim.uri_to_fname(params.textDocument.uri)
    local out = {}
    for _, s in ipairs(scan_symbols(root)) do
      if vim.fs.normalize(s.file) == vim.fs.normalize(file) then
        out[#out + 1] = {
          name = s.name,
          kind = s.kind == K.Constant and 14 or 12,
          location = {
            uri = params.textDocument.uri,
            range = {
              start = { line = s.line, character = 0 },
              ["end"] = { line = s.line, character = #s.text },
            },
          },
        }
      end
    end
    return out
  end

  local notifications = {
    ["textDocument/didOpen"] = function(p) run_diagnostics(p.textDocument.uri) end,
    ["textDocument/didSave"] = function(p) run_diagnostics(p.textDocument.uri) end,
  }

  local srv = {}

  function srv.request(method, params, callback)
    local h = handlers[method]
    id = id + 1
    local ok, result = pcall(function() return h and h(params) or vim.NIL end)
    if ok then
      callback(nil, result)
    else
      callback({ code = -32603, message = tostring(result) }, nil)
    end
    return true, id
  end

  function srv.notify(method, params)
    local h = notifications[method]
    if h then h(params) end
    return true
  end

  function srv.is_closing() return closing end

  function srv.terminate() closing = true end

  return srv
end

function M.setup()
  vim.lsp.config("rgbasm_ls", {
    cmd = server,
    filetypes = { "rgbasm" },
    root_markers = { "first.sh", ".git" },
  })
  vim.lsp.enable "rgbasm_ls"
end

return M
