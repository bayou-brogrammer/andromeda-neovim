require("milkyvim.config").load_plugins({
  ---------------------------------------------------------------------
  -- * mini.pairs * -----------------------------------------------
  -- * https://github.com/echasnovski/mini.pairs
  ---------------------------------------------------------------------
  {
    "mini.pairs",
    opts = {},
    keys = {
      {
        "<leader>up",
        desc = "Toggle auto pairs",
        function()
          local Util = require("lazy.core.util")
          vim.g.minipairs_disable = not vim.g.minipairs_disable
          if vim.g.minipairs_disable then
            Util.warn("Disabled auto pairs", { title = "Option" })
          else
            Util.info("Enabled auto pairs", { title = "Option" })
          end
        end,
      },
    },
  },

  ------------------------------------------------
  -- * Nvim surround * ---------------------------
  -- * https://github.com/kylechui/nvim-surround
  ------------------------------------------------
  { "nvim-surround" },

  ---------------------------------------------------------------------
  -- * Comment string * -----------------------------------------------
  -- * https://github.com/JoosepAlviste/nvim-ts-context-commentstring
  ---------------------------------------------------------------------
  { "ts_context_commentstring", opts = { enable_autocmd = false } },

  ---------------------------------------------
  -- * Comment * ------------------------------
  -- * https://github.com/numToStr/Comment.nvim
  ---------------------------------------------
  {
    "Comment",
    opts = {
      ---Add a space b/w comment and the line
      padding = true,
      ---Whether the cursor should stay at its position
      sticky = true,
      ---Lines to be ignored while (un)comment
      ignore = nil,
      mappings = {
        ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
        basic = true,
        ---Extra mapping; `gco`, `gcO`, `gcA`
        extra = true,
      },
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    },
  },

  ---------------------------------------------------------------------
  -- * mini.ai * -----------------------------------------------
  -- * https://github.com/echasnovski/mini.ai
  ---------------------------------------------------------------------
  {
    "mini.ai",
    opts = function()
      local ai = require("mini.ai")

      return {
        n_lines = 500,
        custom_textobjects = {
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
        },
      }
    end,
    config = function(opts)
      require("mini.ai").setup(opts)

      local i = {
        [" "] = "Whitespace",
        ['"'] = 'Balanced "',
        ["'"] = "Balanced '",
        ["`"] = "Balanced `",
        ["("] = "Balanced (",
        [")"] = "Balanced ) including white-space",
        [">"] = "Balanced > including white-space",
        ["<lt>"] = "Balanced <",
        ["]"] = "Balanced ] including white-space",
        ["["] = "Balanced [",
        ["}"] = "Balanced } including white-space",
        ["{"] = "Balanced {",
        ["?"] = "User Prompt",
        _ = "Underscore",
        a = "Argument",
        b = "Balanced ), ], }",
        c = "Class",
        f = "Function",
        o = "Block, conditional, loop",
        q = "Quote `, \", '",
        t = "Tag",
      }

      local a = vim.deepcopy(i)
      for k, v in pairs(a) do
        a[k] = v:gsub(" including.*", "")
      end

      local ic = vim.deepcopy(i)
      local ac = vim.deepcopy(a)
      for key, name in pairs({ n = "Next", l = "Last" }) do
        i[key] = vim.tbl_extend("force", { name = "Inside " .. name .. " textobject" }, ic)
        a[key] = vim.tbl_extend("force", { name = "Around " .. name .. " textobject" }, ac)
      end
      require("which-key").register({
        mode = { "o", "x" },
        i = i,
        a = a,
      })
    end,
  },

  ---------------------------------------------
  -- * Harpoon * ------------------------------
  -- * https://github.com/ThePrimeagen/harpoon
  ---------------------------------------------
  {
    "harpoon",
    keys = {
      {
        "<leader>hh",
        [[:lua require("harpoon.ui").toggle_quick_menu()<CR>]],
        desc = "open harpoon menu",
        noremap = true,
      },
      {
        "<leader>hm",
        [[:lua require("harpoon.mark").add_file()<CR>]],
        desc = "add file to harpoon",
        noremap = true,
      },

      {
        "<leader>hb",
        [[:lua require("harpoon.ui").nav_prev()<CR>]],
        desc = "open prev harpoon",
        noremap = true,
      },

      {
        "<leader>hn",
        [[:lua require("harpoon.ui").nav_next()<CR>]],
        desc = "open next harpoon",
        noremap = true,
      },
    },
  },
})
