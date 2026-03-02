---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "codelldb") then
        table.insert(opts.ensure_installed, "codelldb")
      end
    end,
  },
  {
    "mfussenegger/nvim-dap",
    opts = function(_, opts)
      local dap = require "dap"

      vim.keymap.set("n", "<Up>", function()
        dap.continue()
      end, { desc = "Debug continue/start" })
      vim.keymap.set("n", "<Right>", function()
        dap.step_into()
      end, { desc = "Debug step into" })
      vim.keymap.set("n", "<Down>", function()
        dap.step_over()
      end, { desc = "Debug step over" })
      vim.keymap.set("n", "<Left>", function()
        dap.step_out()
      end, { desc = "Debug step out" })

      local mason_codelldb = vim.fn.stdpath("data") .. "/mason/bin/codelldb"
      local codelldb_cmd = vim.fn.executable(mason_codelldb) == 1 and mason_codelldb or "codelldb"

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = codelldb_cmd,
          args = { "--port", "${port}" },
        },
      }

      local cpp_launch = {
        name = "Launch (codelldb)",
        type = "codelldb",
        request = "launch",
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
      }

      local function ensure_config(lang)
        dap.configurations[lang] = dap.configurations[lang] or {}
        for _, config in ipairs(dap.configurations[lang]) do
          if config.name == cpp_launch.name then return end
        end
        table.insert(dap.configurations[lang], cpp_launch)
      end

      ensure_config "cpp"
      ensure_config "c"
      ensure_config "rust"

      return opts
    end,
  },
}
