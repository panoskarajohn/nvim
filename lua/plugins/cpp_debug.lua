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

      require("dap.ext.vscode").load_launchjs(nil, { lldb = { "c", "cpp" } })

      vim.keymap.set("n", "<leader>dt", function()
        dap.continue()
      end, { desc = "Debug from launch.json" })

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
