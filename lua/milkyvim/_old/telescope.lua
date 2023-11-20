local Utils = require("milkyvim.utils")
local actions = require("telescope.actions")

require("milkyvim.config").load_plugins({

  {
    "telescope",
    cmd = "Telescope",
    dependencies = {
      {
        "telescope-fzf-native",
        config = function()
          require("telescope").load_extension("fzf")
        end,
      },

      {
        "telescope-undo",
        config = function()
          require("telescope").load_extension("undo")
        end,
      },

      {
        "telescope-zoxide",
        dependencies = { "nvim-lua/popup.nvim", "nvim-lua/plenary.nvim" },
        config = function()
          require("telescope").load_extension("zoxide")
        end,
      },
    },

    keys = {
      {
        "<leader>,",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
        desc = "Switch Buffer",
      },
      { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "Command History" },

      -------------
      -- find
      -------------

      -- Files

      { "<leader>ff", Utils.telescope("files"), desc = "Find Files (root dir)" },
      { "<leader><space>", Utils.telescope("files"), desc = "Find Files (root dir)" },
      { "<leader>fF", Utils.telescope("files", { cwd = false }), desc = "Find Files (cwd)" },

      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
      { "<leader>fR", Utils.telescope("oldfiles", { cwd = vim.loop.cwd() }), desc = "Recent (cwd)" },

      { "<leader>fc", Utils.telescope.config_files(), desc = "Find Config File" },
      { "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Buffers" },

      -------------
      -- git
      -------------
      { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "commits" },
      { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "status" },

      -------------
      -- search
      -------------

      -- grep
      { "<leader>/", Utils.telescope("live_grep"), desc = "Grep (root dir)" },
      { "<leader>sg", Utils.telescope("live_grep"), desc = "Grep (root dir)" },
      { "<leader>sG", Utils.telescope("live_grep", { cwd = false }), desc = "Grep (cwd)" },

      { "<leader>sw", Utils.telescope("grep_string"), mode = "v", desc = "Selection (root dir)" },
      { "<leader>sw", Utils.telescope("grep_string", { word_match = "-w" }), desc = "Word (root dir)" },
      { "<leader>sW", Utils.telescope("grep_string", { cwd = false }), mode = "v", desc = "Selection (cwd)" },
      { "<leader>sW", Utils.telescope("grep_string", { cwd = false, word_match = "-w" }), desc = "Word (cwd)" },
      { "<leader>uC", Utils.telescope("colorscheme", { enable_preview = true }), desc = "Colorscheme with preview" },

      { "<leader>sC", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { '<leader>s"', "<cmd>Telescope registers<cr>", desc = "Registers" },
      { "<leader>sa", "<cmd>Telescope autocommands<cr>", desc = "Auto Commands" },
      { "<leader>sc", "<cmd>Telescope command_history<cr>", desc = "Command History" },
      { "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer" },
      { "<leader>sD", "<cmd>Telescope diagnostics<cr>", desc = "Workspace diagnostics" },
      { "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Document diagnostics" },

      { "<leader>sR", "<cmd>Telescope resume<cr>", desc = "Resume" },
      { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Key Maps" },
      { "<leader>sm", "<cmd>Telescope marks<cr>", desc = "Jump to Mark" },
      { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
      { "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "Options" },
      { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
      { "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "Search Highlight Groups" },

      {
        "<leader>ss",
        function()
          require("telescope.builtin").lsp_document_symbols({
            symbols = require("milkyvim.config").get_kind_filter(),
          })
        end,
        desc = "Goto Symbol",
      },
      {
        "<leader>sS",
        function()
          require("telescope.builtin").lsp_dynamic_workspace_symbols({
            symbols = require("milkyvim.config").get_kind_filter(),
          })
        end,
        desc = "Goto Symbol (Workspace)",
      },
    },
    opts = function()
      local actions = require("telescope.actions")

      local open_with_trouble = function(...)
        return require("trouble.providers.telescope").open_with_trouble(...)
      end
      local open_selected_with_trouble = function(...)
        return require("trouble.providers.telescope").open_selected_with_trouble(...)
      end
      local find_files_no_ignore = function()
        local action_state = require("telescope.actions.state")
        local line = action_state.get_current_line()
        Utils.telescope("find_files", { no_ignore = true, default_text = line })()
      end
      local find_files_with_hidden = function()
        local action_state = require("telescope.actions.state")
        local line = action_state.get_current_line()
        Utils.telescope("find_files", { hidden = true, default_text = line })()
      end

      return {
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          -- open files in the first window that is an actual file.
          -- use the current window if no other window is available.
          get_selection_window = function()
            local wins = vim.api.nvim_list_wins()
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == "" then
                return win
              end
            end
            return 0
          end,
          mappings = {
            i = {
              ["<c-t>"] = open_with_trouble,
              ["<a-t>"] = open_selected_with_trouble,
              ["<a-i>"] = find_files_no_ignore,
              ["<a-h>"] = find_files_with_hidden,
              ["<C-Down>"] = actions.cycle_history_next,
              ["<C-Up>"] = actions.cycle_history_prev,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-b>"] = actions.preview_scrolling_up,
            },
            n = {
              ["q"] = actions.close,
            },
          },
        },

        extensions = {
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          },
        },
      }
    end,
  },
})
