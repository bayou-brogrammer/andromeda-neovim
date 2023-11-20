local Utils = require("milkyvim.utils")

---@class milkyvim.utils.lualine
local M = {}

-------------------
-- * Helpers * ----
-------------------

---@param component any
---@param text string
---@param hl_group? string
---@return string
function M.format(component, text, hl_group)
  if not hl_group then
    return text
  end

  ---@type table<string, string>
  component.hl_cache = component.hl_cache or {}
  local lualine_hl_group = component.hl_cache[hl_group]

  if not lualine_hl_group then
    local utils = require("lualine.utils.utils")
    lualine_hl_group = component:create_hl({ fg = utils.extract_highlight_colors(hl_group, "fg") }, "LV_" .. hl_group)
    component.hl_cache[hl_group] = lualine_hl_group
  end

  return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
end

----------------
-- * Root * ----
----------------

---@param opts? {cwd:false, subdirectory: true, parent: true, other: true, icon?:string}
function M.root_dir(opts)
  opts = vim.tbl_extend("force", {
    cwd = false,
    subdirectory = true,
    parent = true,
    other = true,
    icon = "󱉭 ",
    color = Utils.ui.fg("Special"),
  }, opts or {})

  local function get()
    local cwd = Utils.root.cwd()
    local root = Utils.root.get({ normalize = true })
    local name = vim.fs.basename(root)

    if root == cwd then
      -- root is cwd
      return opts.cwd and name
    elseif root:find(cwd, 1, true) == 1 then
      -- root is subdirectory of cwd
      return opts.subdirectory and name
    elseif cwd:find(root, 1, true) == 1 then
      -- root is parent directory of cwd
      return opts.parent and name
    else
      -- root and cwd are not related
      return opts.other and name
    end
  end

  return {
    function()
      return (opts.icon and opts.icon .. " ") .. get()
    end,
    cond = function()
      return type(get()) == "string"
    end,
    color = opts.color,
  }
end

-----------------------
-- * Pretty Path * ----
-----------------------

---@param opts? {relative: "cwd"|"root", modified_hl: string?}
function M.pretty_path(opts)
  opts = vim.tbl_extend("force", {
    relative = "cwd",
    modified_hl = "Constant",
  }, opts or {})

  return function(self)
    local path = vim.fn.expand("%:p") --[[@as string]]

    if path == "" then
      return ""
    end

    local cwd = Utils.root.cwd()
    local root = Utils.root.get({ normalize = true })

    if opts.relative == "cwd" and path:find(cwd, 1, true) == 1 then
      path = path:sub(#cwd + 2)
    else
      path = path:sub(#root + 2)
    end

    local sep = package.config:sub(1, 1)
    local parts = vim.split(path, "[\\/]")
    if #parts > 3 then
      parts = { parts[1], "…", parts[#parts - 1], parts[#parts] }
    end

    if opts.modified_hl and vim.bo.modified then
      parts[#parts] = M.format(self, parts[#parts], opts.modified_hl)
    end

    return table.concat(parts, sep)
  end
end

return M
