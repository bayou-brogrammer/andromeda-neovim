local Utils = require("milkyvim.utils")

require("milkyvim.config").load_plugins({
  -----------------------------------------
  -- * Luasnip * -------------------------
  -- * https://github.com/L3MON4D3/LuaSnip
  -----------------------------------------
  {
    "luasnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end,
    },
    opts = { history = true, delete_check_events = "TextChanged" },
  },

  -- [[ Configure nvim-cmp ]]
  -- See `:help cmp`
  -----------------------------------------
  -- * Nvim CMP * -------------------------
  -- * https://github.com/hrsh7th/nvim-cmp
  -----------------------------------------
  -- ! This also setups supertab for completion and snippets ! --
  {
    "hrsh7th/nvim-cmp",
    version = false, -- last release is way too old
    event = "InsertEnter",
    dependencies = {
      "cmp-path",
      "cmp-emoji",
      "cmp-buffer",
      "cmp-nvim-lsp",
      "cmp_luasnip",
    },
    opts = function()
      vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })

      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local defaults = require("cmp.config.default")()

      return {
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-Space>"] = cmp.mapping.complete(),

          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),

          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),

          -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-CR>"] = function(fallback)
            cmp.abort()
            fallback()
          end,

          -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ["<S-CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),

          -- ! Supertab-like behavior ! --
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
              -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
              -- this way you will only jump inside the snippet region
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "path" },
          { name = "emoji" },
          { name = "luasnip" },
          { name = "nvim_lsp" },
        }, {
          { name = "buffer" },
        }),
        formatting = {
          format = function(_, item)
            local icons = require("milkyvim.config").icons.kinds
            if icons[item.kind] then
              item.kind = icons[item.kind] .. item.kind
            end
            return item
          end,
        },
        experimental = {
          ghost_text = { hl_group = "CmpGhostText" },
        },
        sorting = defaults.sorting,
      }
    end,
    config = function(_, opts)
      for _, source in ipairs(opts.sources) do
        source.group_index = source.group_index or 1
      end

      local cmp = require("cmp")
      cmp.setup(opts)

      cmp.setup.filetype("gitcommit", {
        sources = cmp.config.sources({
          { name = "git" }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
        }, {
          { name = "buffer" },
        }),
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          --[[ , keyword_length = 3  ]]
          { name = "nvim_lsp_document_symbol" },
          { name = "buffer" },
          { name = "cmdline_history" },
        },
        view = {
          entries = { name = "wildmenu", separator = "|" },
        },
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
  },
})
