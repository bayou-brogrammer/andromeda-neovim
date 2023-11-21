return {
	milkyvim.use("catppuccin/catppuccin.nvim", {
		lazy = true,
		event = "VeryLazy",
		config = function()
			vim.cmd([[
				colorscheme catppuccin-mocha
				highlight NvimTreeIndentMarker guifg=#A6E3A1
				highlight NvimTreeFolderArrowClosed guifg=#A6E3A1
				highlight NvimTreeFolderArrowOpen guifg=#A6E3A1
				highlight WinSeparator guifg=#A6E3A1
			]])
		end,
	}),

	-- milkyvim.use("rktjmp/lush.nvim", { event = "VeryLazy", lazy = true }),

	-- milkyvim.use("NvChad/nvim-colorizer.lua", {
	-- 	event = "VeryLazy",
	-- 	config = function()
	-- 		require("colorizer").setup({
	-- 			user_default_options = {
	-- 				RGB = true,
	-- 				RRGGBB = true,
	-- 				names = false,
	-- 				RRGGBBAA = true,
	-- 				AARRGGBB = true,
	-- 				rgb_fn = true,
	-- 				hsl_fn = true,
	-- 				mode = "background",
	-- 				tailwind = true,
	-- 			},
	-- 		})
	-- 	end,
	-- }),
}
