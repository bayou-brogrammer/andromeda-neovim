local Utils = require("milkyvim.utils")

---@class milkyvim.utils.file
local M = {}

local fileExtension = ".lua"

function M.getFileName(file)
  return file:match("[^/]*.lua$")
end

function M.isLuaFile(filename)
  return filename:sub(-#fileExtension) == fileExtension
end

function M.loadAll(path)
  local scan = require("plenary.scandir")

  for _, file in ipairs(scan.scan_dir(Utils.root() .. "/lua/" .. path:gsub("[.]", "/"), { depth = 0 })) do
    local fileName = M.getFileName(file)

    if M.isLuaFile(file) and M.getFileName(file) ~= "init.lua" then
      dofile(file)
    end
  end
end

return M
