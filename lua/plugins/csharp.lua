return {
  { "Hoffs/omnisharp-extended-lsp.nvim", lazy = true },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "c_sharp" } },
  },

  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "csharpier", "netcoredbg" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Add ~/.dotnet/tools to PATH if missing
      local dotnet_tools = os.getenv("HOME") .. "/.dotnet/tools"
      if not string.find(vim.env.PATH, dotnet_tools, 1, true) then
        vim.env.PATH = vim.env.PATH .. ":" .. dotnet_tools
      end

      -- LazyVim recommended OmniSharp setup
      opts.servers = opts.servers or {}
      opts.servers.omnisharp = {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/OmniSharp" },
        enable_roslyn_analyzers = true,
        organize_imports_on_format = true,
        enable_import_completion = true,
        enable_editorconfig_support = true,
        handlers = {
          ["textDocument/definition"] = function(...)
            return require("omnisharp_extended").handler(...)
          end,
        },
        keys = {
          {
            "gd",
            LazyVim.has("telescope.nvim") and function()
              require("omnisharp_extended").telescope_lsp_definitions()
            end or function()
              require("omnisharp_extended").lsp_definitions()
            end,
            desc = "Goto Definition",
          },
        },
      }
    end,
  },

  {
    "Issafalcon/neotest-dotnet",
  },

  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = opts.sources or {}
      table.insert(opts.sources, nls.builtins.formatting.csharpier)
    end,
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        cs = { "csharpier" },
      },
      formatters = {
        csharpier = {
          command = "dotnet-csharpier",
          args = { "--write-stdout" },
        },
      },
    },
  },

  opts = function()
    local dap = require("dap")
    if not dap.adapters["netcoredbg"] then
      require("dap").adapters["netcoredbg"] = {
        type = "executable",
        command = vim.fn.exepath("netcoredbg"),
        args = { "--interpreter=vscode" },
        options = {
          detached = false,
        },
      }
    end
    for _, lang in ipairs({ "cs", "fsharp", "vb" }) do
      if not dap.configurations[lang] then
        dap.configurations[lang] = {
          {
            type = "netcoredbg",
            name = "Launch file",
            request = "launch",
            ---@diagnostic disable-next-line: redundant-parameter
            program = function()
              return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
          },
        }
      end
    end
  end,

  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "Issafalcon/neotest-dotnet",
    },
    opts = {
      adapters = {
        ["neotest-dotnet"] = {
          -- Here we can set options for neotest-dotnet
        },
      },
    },
  },
}
