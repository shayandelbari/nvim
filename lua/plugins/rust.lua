return {
  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        crates = {
          enabled = true,
        },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "rust", "ron" } },
  },

  {
    "mrcjkb/rustaceanvim",
    version = vim.fn.has("nvim-0.10.0") == 0 and "^4" or false,
    ft = { "rust" },
    opts = {
      server = {
        on_attach = function(_, bufnr)
          vim.keymap.set("n", "<leader>cR", function()
            vim.cmd.RustLsp("codeAction")
          end, { desc = "Code Action", buffer = bufnr })
          vim.keymap.set("n", "<leader>dr", function()
            vim.cmd.RustLsp("debuggables")
          end, { desc = "Rust Debuggables", buffer = bufnr })
        end,
        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = { enable = true },
            },
            checkOnSave = true,
            diagnostics = { enable = true },
            procMacro = {
              enable = true,
              ignored = {
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["async-recursion"] = { "async_recursion" },
              },
            },
            files = {
              excludeDirs = {
                ".direnv",
                ".git",
                ".github",
                ".gitlab",
                "bin",
                "node_modules",
                "target",
                "venv",
                ".venv",
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      local function setup_dap()
        local ok, registry = pcall(require, "mason-registry")
        if not ok then
          vim.notify("mason-registry not available", vim.log.levels.WARN)
          return
        end

        if not registry.has_package("codelldb") then
          vim.notify("Mason package 'codelldb' not found. Run :MasonInstall codelldb", vim.log.levels.WARN)
          return
        end

        local package = registry.get_package("codelldb")
        if not package then
          vim.notify("Failed to load Mason package 'codelldb'", vim.log.levels.ERROR)
          return
        end

        local package_path = package:get_install_path()
        local codelldb = package_path .. "/extension/adapter/codelldb"

        local uname = io.popen("uname"):read("*l")
        local lib_name = (uname == "Linux") and "liblldb.so" or "liblldb.dylib"
        local library_path = package_path .. "/extension/lldb/lib/" .. lib_name

        opts.dap = {
          adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb, library_path),
        }
      end

      -- ✅ Wait for Mason registry to be ready
      local ok, registry = pcall(require, "mason-registry")
      if ok then
        if registry.refresh then
          registry.refresh(function()
            setup_dap()
          end)
        else
          setup_dap()
        end
      end

      -- Merge opts globally
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})

      -- Warn if rust-analyzer missing
      if vim.fn.executable("rust-analyzer") == 0 then
        LazyVim.error(
          "**rust-analyzer** not found in PATH, please install it.\nhttps://rust-analyzer.github.io/",
          { title = "rustaceanvim" }
        )
      end
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bacon_ls = {
          enabled = diagnostics == "bacon-ls",
        },
        rust_analyzer = { enabled = false },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "codelldb" })
      if diagnostics == "bacon-ls" then
        vim.list_extend(opts.ensure_installed, { "bacon" })
      end
    end,
  },

  {
    "nvim-neotest/neotest",
    optional = true,
    opts = {
      adapters = {
        ["rustaceanvim.neotest"] = {},
      },
    },
  },
}
