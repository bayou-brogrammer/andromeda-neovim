local Utils = require("milkyvim.utils")

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
require("milkyvim.config").load_plugins({
  ---------------------------------------------------------
  -- * Treesitter * ---------------------------------------
  -- * https://github.com/nvim-treesitter/nvim-treesitter
  ---------------------------------------------------------

  {
    "nvim-treesitter.configs",
    -- cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },

    init = function(plugin)
      -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
      -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
      -- no longer trigger the **nvim-treeitter** module to be loaded in time.
      -- Luckily, the only thins that those plugins need are the custom queries, which we make available
      -- during startup.
      require("nvim-treesitter.query_predicates")
    end,

    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        config = function()
          -- When in diff mode, we want to use the default
          -- vim text objects c & C instead of the treesitter ones.
          local move = require("nvim-treesitter.textobjects.move") ---@type table<string,fun(...)>
          local configs = require("nvim-treesitter.configs")
          for name, fn in pairs(move) do
            if name:find("goto") == 1 then
              move[name] = function(q, ...)
                if vim.wo.diff then
                  local config = configs.get_module("textobjects.move")[name] ---@type table<string,string>
                  for key, query in pairs(config or {}) do
                    if q == query and key:find("[%]%[][cC]") then
                      vim.cmd("normal! " .. key)
                      return
                    end
                  end
                end

                return fn(q, ...)
              end
            end
          end
        end,
      },
    },

    keys = {
      { "<c-space>", desc = "Increment selection" },
      { "<bs>", desc = "Decrement selection", mode = "x" },
    },

    opts = {
      indent = { enable = true },
      highlight = { enable = true },

      incremental_selection = {
        enable = true,
        keymaps = {
          scope_incremental = false,
          node_decremental = "<bs>",
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
        },
      },

      textobjects = {
        move = {
          enable = true,
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
        },
      },
    },

    config = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        ---@type table<string, boolean>
        local added = {}
        opts.ensure_installed = vim.tbl_filter(function(lang)
          if added[lang] then
            return false
          end
          added[lang] = true
          return true
        end, opts.ensure_installed)
      end

      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -----------------------------------------------------------------
  -- * Treesitter Context * ---------------------------------------
  -- * https://github.com/nvim-treesitter/nvim-treesitter-context
  -----------------------------------------------------------------
  {
    "treesitter-context",
    opts = { mode = "cursor", max_lines = 3 },
    keys = {
      {
        "<leader>ut",
        function()
          local Util = require("milkyvim.utils")
          local tsc = require("treesitter-context")
          tsc.toggle()
          if Util.inject.get_upvalue(tsc.toggle, "enabled") then
            Util.info("Enabled Treesitter Context", { title = "Option" })
          else
            Util.warn("Disabled Treesitter Context", { title = "Option" })
          end
        end,
        desc = "Toggle Treesitter Context",
      },
    },
  },

  ------------------------------------------------
  -- * Autotag * ---------------------------------
  -- * https://github.com/windwp/nvim-ts-autotag
  ------------------------------------------------
  { "nvim-ts-autotag" },
})
