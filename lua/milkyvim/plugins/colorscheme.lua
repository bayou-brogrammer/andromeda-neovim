local colorscheme_spec = milkyvim.use("catppuccin/catppuccin.nvim", {
  lazy = false,
  config = function()
    vim.cmd.colorscheme("catppuccin-mocha")
  end,
})

return {
  colorscheme_spec,
}
