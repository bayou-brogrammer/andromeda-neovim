---@diagnostic disable: undefined-field
local Utils = require("milkyvim.utils")

---@class milkyvim.utils.toggle
local M = {}

-------------------------------
--* Number
-------------------------------

local nu = { number = true, relativenumber = true }
function M.number()
  if vim.opt_local.number:get() or vim.opt_local.relativenumber:get() then
    nu = { number = vim.opt_local.number:get(), relativenumber = vim.opt_local.relativenumber:get() }
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    Utils.warn("Disabled line numbers", { title = "Option" })
  else
    vim.opt_local.number = nu.number
    vim.opt_local.relativenumber = nu.relativenumber
    Utils.info("Enabled line numbers", { title = "Option" })
  end
end

-------------------------------
--* Diagnostics
-------------------------------

local enabled = true
function M.diagnostics()
  enabled = not enabled
  if enabled then
    vim.diagnostic.enable()
    Utils.info("Enabled diagnostics", { title = "Diagnostics" })
  else
    vim.diagnostic.disable()
    Utils.warn("Disabled diagnostics", { title = "Diagnostics" })
  end
end

-------------------------------
--* Toggle
-------------------------------

---@param silent boolean?
---@param values? {[1]:any, [2]:any}
function M.option(option, silent, values)
  if values then
    if vim.opt_local[option]:get() == values[1] then
      vim.opt_local[option] = values[2]
    else
      vim.opt_local[option] = values[1]
    end

    return Utils.info("Set " .. option .. " to " .. vim.opt_local[option]:get(), { title = "Option" })
  end

  vim.opt_local[option] = not vim.opt_local[option]:get()

  if not silent then
    if vim.opt_local[option]:get() then
      Utils.info("Enabled " .. option, { title = "Option" })
    else
      Utils.warn("Disabled " .. option, { title = "Option" })
    end
  end
end

setmetatable(M, {
  __call = function(m, ...)
    return m.option(...)
  end,
})

return M
