return {
	milkyvim.use("folke/lazy.nvim", { enabled = false }),

	milkyvim.use("nvim-lua/plenary.nvim"),

	milkyvim.use("folke/which-key.nvim", {
		config = function()
			require("which-key").setup({
				plugins = {
					presets = {
						g = false,
					},
				},
			})
		end,
	}),
}
