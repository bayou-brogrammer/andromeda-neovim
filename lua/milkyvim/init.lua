require("milkyvim.config").load()

require("lazy").setup("milkyvim.plugins", {
  default = {
    lazy = true,
    version = false, -- always use the latest git commit
  },

  -- You can Set `NVIM_DEV` environment variable to modify where [lazy.nvim][lazy.nvim]
  -- should look for `dev = true` plugins.
  dev = { path = vim.env.NVIM_DEV },

  checker = { enabled = false },
  install = { colorscheme = { "tokyonight", "catppuccin" } },

  performance = {
    cache = {
      enabled = true,
    },
    rtp = {
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
