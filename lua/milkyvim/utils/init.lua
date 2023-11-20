local LazyUtil = require("lazy.core.util")

---@alias LazyNotifyOpts {lang?:string, title?:string, level?:number, once?:boolean, stacktrace?:boolean, stacklevel?:number}

---@class LazyUtilCore
---@field norm fun(path: string): string
---@field info fun(msg: string|string[], opts?: LazyNotifyOpts)
---@field warn fun(msg: string|string[], opts?: LazyNotifyOpts)
---@field error fun(msg: string|string[], opts?: LazyNotifyOpts)
---@field track fun(data: (string|{[string]:string})?, time: number?)
---@field try fun(fn: fun(), opts: string|{msg:string, on_error:fun(msg)})

---@class milkyvim.utils: LazyUtilCore
---@field ui milkyvim.utils.ui
---@field lsp milkyvim.utils.lsp
---@field root milkyvim.utils.root
---@field file milkyvim.utils.file
---@field plugin milkyvim.utils.plugin
---@field format milkyvim.utils.format
---@field toggle milkyvim.utils.toggle
---@field inject milkyvim.utils.inject
---@field lualine milkyvim.utils.lualine
---@field telescope milkyvim.utils.telescope
local M = {}

setmetatable(M, {
	__index = function(t, k)
		if LazyUtil[k] then
			return LazyUtil[k]
		end

		---@diagnostic disable-next-line: no-unknown
		t[k] = require("milkyvim.utils." .. k)
		return t[k]
	end,
})

function M.is_win()
	return vim.loop.os_uname().sysname:find("Windows") ~= nil
end

function M.normalize(spec, results)
	if type(spec) == "string" then
		if not spec:find("/", 1, true) then
			-- spec is a plugin name
			if results then
				table.insert(results, spec)
			end
		else
			vim.print("TODO: normalize path")
			vim.print(spec)
			vim.fn.getchar()
		end
	elseif #spec > 1 or LazyUtil.is_list(spec) then
		for _, s in ipairs(spec) do
			M.normalize(s, results)
		end
	elseif spec[1] then
		table.insert(results, spec)
	else
		LazyUtil:error("Invalid plugin spec " .. vim.inspect(spec))
	end

	return results
end

----------------
-- * Keyamps * -
----------------

function M.map(mode, lhs, rhs, options)
	vim.keymap.set(mode or "n", lhs, rhs, options)
end

function M.nmap(lhs, rhs, options)
	vim.keymap.set("n", lhs, rhs, options)
end

function M.load_keymap(keymap)
	local handle = require("lazy.core.handler.keys").parse(keymap)
	M.map(handle.mode, handle.lhs, handle.rhs or handle.lhs, { desc = handle.desc })
end

function M.load_keymaps(keymaps)
	for _, keymap in ipairs(keymaps) do
		M.load_keymap(keymap)
	end
end

return M
