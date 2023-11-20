local Utils = require("milkyvim.utils")

local M = {}

---@type MilkyPlugin[]
M.plugins = {}

M.kind_filter = {
  help = false,
  markdown = false,
  default = {
    "Class",
    "Constructor",
    "Enum",
    "Field",
    "Function",
    "Interface",
    "Method",
    "Module",
    "Namespace",
    "Package",
    "Property",
    "Struct",
    "Trait",
  },

  -- you can specify a different filter for each filetype
  lua = {
    "Class",
    "Constructor",
    "Enum",
    "Field",
    "Function",
    "Interface",
    "Method",
    "Module",
    "Namespace",
    -- "Package", -- remove package since luals uses it for control flow structures
    "Property",
    "Struct",
    "Trait",
  },
}

M.icons = {
  misc = {
    dots = "󰇘",
  },
  dap = {
    Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
    Breakpoint = " ",
    BreakpointCondition = " ",
    BreakpointRejected = { " ", "DiagnosticError" },
    LogPoint = ".>",
  },
  diagnostics = {
    Error = " ",
    Warn = " ",
    Hint = " ",
    Info = " ",
  },
  git = {
    added = " ",
    modified = " ",
    removed = " ",
  },
  kinds = {
    Array = " ",
    Boolean = "󰨙 ",
    Class = " ",
    Codeium = "󰘦 ",
    Color = " ",
    Control = " ",
    Collapsed = " ",
    Constant = "󰏿 ",
    Constructor = " ",
    Copilot = " ",
    Enum = " ",
    EnumMember = " ",
    Event = " ",
    Field = " ",
    File = " ",
    Folder = " ",
    Function = "󰊕 ",
    Interface = " ",
    Key = " ",
    Keyword = " ",
    Method = "󰊕 ",
    Module = " ",
    Namespace = "󰦮 ",
    Null = " ",
    Number = "󰎠 ",
    Object = " ",
    Operator = " ",
    Package = " ",
    Property = " ",
    Reference = " ",
    Snippet = " ",
    String = " ",
    Struct = "󰆼 ",
    TabNine = "󰏚 ",
    Text = " ",
    TypeParameter = " ",
    Unit = " ",
    Value = " ",
    Variable = "󰀫 ",
  },
}

-- Find either the Nix-generated version of the plugin if it is
-- found, or fall back to fetching it remotely if it is not.
-- Don't mistake this for "use" from packer.nvim
_G.milkyvim = {
  use = function(name, spec)
    spec = spec or {}

    local plugin_name = name:match("[^/]+$")
    local plugin_dir = vim.env.NVIM_PATH .. "/plugins/" .. plugin_name

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
      spec[1] = name
    end

    return spec
  end,
}

function M.lazy_load()
  local lazypath = vim.env.NVIM_PATH .. "/plugins/lazy.nvim"
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
end

function M.load()
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

  M.lazy_load()
end

---@param buf? number
---@return string[]?
function M.get_kind_filter(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local ft = vim.bo[buf].filetype

  if M.kind_filter == false then
    return
  end

  if M.kind_filter[ft] == false then
    return
  end

  return type(M.kind_filter) == "table" and type(M.kind_filter.default) == "table" and M.kind_filter.default or nil
end

return M
