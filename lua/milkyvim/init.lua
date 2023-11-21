require("milkyvim.utils.ui")
require("milkyvim.utils.lualine")

local root = require("milkyvim.utils.root")
local format = require("milkyvim.utils.format")
local plugin = require("milkyvim.utils.plugin")

-------------------------------------------------------------------------------
-- * Global Milkyvim Loader * ---------------------------------------------------------------
-------------------------------------------------------------------------------

local renames = {
	["catppuccin.nvim"] = "catppuccin/nvim",
}

-- Find either the Nix-generated version of the plugin if it is
-- found, or fall back to fetching it remotely if it is not.
-- Don't mistake this for "use" from packer.nvim
_G.milkyvim = {
	use = function(name, spec)
		spec = spec or {}

		local plugin_name = name:match("[^/]+$")
		local plugin_dir = vim.env.PLUGIN_PATH .. "/plugins/" .. plugin_name

		-- This works around the automatic dev plugin functionality, and falls
		-- back properly to the Nix-generated version if it exists.
		if spec.dev then
			local dev_plugin_dir = vim.env.HOME .. "/Code/NeovimPlugins/" .. plugin_name
			if vim.fn.isdirectory(dev_plugin_dir) > 0 then
				spec.dir = dev_plugin_dir
				spec.dev = nil
				return spec
			end
		end

		if vim.fn.isdirectory(plugin_dir) > 0 then
			spec.dir = plugin_dir
		else
			spec[1] = renames[plugin_name] or spec.name or name
		end

		return spec
	end,
}

-------------------------------------------------------------------------------
-- * Milkyvim * ---------------------------------------------------------------
-------------------------------------------------------------------------------

vim.loader.enable()

local modules = {
	"options",
	"autocmds",
	"keymaps",
	-- "commands",
	-- "filetypes",
}

for _, module in ipairs(modules) do
	local status_ok, fault = pcall(require, "milkyvim.config." .. module)
	if not status_ok then
		vim.api.nvim_err_writeln("Failed to load " .. module .. "\n\n" .. fault)
	end
end

root.setup()
format.setup()
plugin.setup()

local lazypath = vim.env.PLUGIN_PATH .. "/plugins/lazy.nvim"
if vim.fn.isdirectory(lazypath) == 0 then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup({
	-- You can Set `NVIM_DEV` environment variable to modify where [lazy.nvim][lazy.nvim]
	-- should look for `dev = true` plugins.
	dev = { path = vim.env.PLUGIN_PATH },
	-- root = vim.env.PLUGIN_PATH .. "/plugins",

	spec = {
		{ import = "milkyvim.plugins" },
	},

	default = {
		lazy = true,
		version = false, -- always use the latest git commit
	},

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

	profiling = {
		-- Enables extra stats on the debug tab related to the loader cache.
		-- Additionally gathers stats about all package.loaders
		loader = true,
		-- Track each new require in the Lazy profiling tab
		require = true,
	},
})
