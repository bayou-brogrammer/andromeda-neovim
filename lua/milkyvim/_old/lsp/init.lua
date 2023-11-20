local Utils = require("milkyvim.utils")
local categories = require("nixCats")

---------------------
-- * LSP Options * --
---------------------

-- LSP Info
vim.g.lsp_zero_extend_cmp = true
vim.g.lsp_zero_api_warnings = true
vim.g.lsp_zero_ui_signcolumn = true
vim.g.lsp_zero_ui_float_border = "double"

local opts = {
  -- options for vim.diagnostic.config()
  diagnostics = {
    underline = true,
    severity_sort = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
      -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
      -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
      -- prefix = "icons",
    },
  },

  -- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
  -- Be aware that you also will need to properly configure your LSP server to
  -- provide the inlay hints.
  inlay_hints = {
    enabled = false,
  },
}

---------------------
-- * LSP  * ---------
---------------------

if categories.lspDebugMode then
  vim.lsp.set_log_level("debug")
end

--! Setup neodev
require("neodev").setup({})
require("neoconf").setup({
  plugins = {
    lua_ls = {
      enabled = true,
      enabled_for_neovim_config = true,
    },
  },
})

--! Setup lsp-zero (helps with lspconfig)
local lsp_zero = require("lsp-zero")
lsp_zero.extend_lspconfig()

--! Setup mason
require("milkyvim.plugins.lsp.mason")

-- --! setup mason-lspconfig
require("mason-lspconfig").setup({
  automatic_installation = true,
  handlers = { lsp_zero.default_setup },
  ensure_installed = { "nil_ls" },
})

-- setup autoformat
Utils.format.register(Utils.lsp.formatter())

--! setup keymaps
lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({ buffer = bufnr, preserve_mappings = false })
end)

--! register_capability
local register_capability = vim.lsp.handlers["client/registerCapability"]
vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
  local ret = register_capability(err, res, ctx)
  local client_id = ctx.client_id
  local client = vim.lsp.get_client_by_id(client_id)
  local buffer = vim.api.nvim_get_current_buf()
  lsp_zero.on_attach(client, buffer)
  return ret
end

--! diagnostics
for name, icon in pairs(require("milkyvim.config").icons.diagnostics) do
  name = "DiagnosticSign" .. name
  vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
end

if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
  opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
    or function(diagnostic)
      local icons = require("milkyvim.config").icons.diagnostics
      for d, icon in pairs(icons) do
        if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
          return icon
        end
      end
    end
end

vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

--! inlay hints
local inlay_hint = vim.lsp.buf.inlay_hint or vim.lsp.inlay_hint
if opts.inlay_hints.enabled and inlay_hint then
  Utils.lsp.on_attach(function(client, buffer)
    if client.supports_method("textDocument/inlayHint") then
      inlay_hint.on_inlayhint(buffer, true)
    end
  end)
end

-- require("milkyvim.plugins.lsp.servers")
lsp_zero.setup_servers({ "lua_ls", "rust_analyzer", "nil_ls" })

-- vim.defer_fn(function()
--   if categories.lspDebugMode then
--     vim.lsp.set_log_level("debug")
--   end

--   --! Setup neodev
--   require("neodev").setup({})
--   require("neoconf").setup({
--     plugins = {
--       lua_ls = {
--         enabled = true,
--         enabled_for_neovim_config = true,
--       },
--     },
--   })

--   --! Setup lsp-zero (helps with lspconfig)
--   local lsp_zero = require("lsp-zero")
--   lsp_zero.extend_lspconfig()

--   --! Setup mason
--   require("mason").setup()

--   -- setup autoformat
--   Utils.format.register(Utils.lsp.formatter())

--   --! setup keymaps
--   lsp_zero.on_attach(function(client, bufnr)
--     -- see :help lsp-zero-keybindings
--     -- to learn the available actions
--     lsp_zero.default_keymaps({ buffer = bufnr, preserve_mappings = false })
--   end)

--   --! register_capability
--   local register_capability = vim.lsp.handlers["client/registerCapability"]
--   vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
--     local ret = register_capability(err, res, ctx)
--     local client_id = ctx.client_id
--     local client = vim.lsp.get_client_by_id(client_id)
--     local buffer = vim.api.nvim_get_current_buf()
--     lsp_zero.on_attach(client, buffer)
--     return ret
--   end

--   --! diagnostics
--   for name, icon in pairs(require("milkyvim.config").icons.diagnostics) do
--     name = "DiagnosticSign" .. name
--     vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
--   end

--   if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
--     opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
--       or function(diagnostic)
--         local icons = require("milkyvim.config").icons.diagnostics
--         for d, icon in pairs(icons) do
--           if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
--             return icon
--           end
--         end
--       end
--   end

--   vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

--   --! inlay hints
--   local inlay_hint = vim.lsp.buf.inlay_hint or vim.lsp.inlay_hint
--   if opts.inlay_hints.enabled and inlay_hint then
--     Utils.lsp.on_attach(function(client, buffer)
--       if client.supports_method("textDocument/inlayHint") then
--         inlay_hint.on_inlayhint(buffer, true)
--       end
--     end)
--   end

--   -- --! setup mason-lspconfig
--   require("mason-lspconfig").setup({
--     automatic_installation = true,
--     handlers = { lsp_zero.default_setup },
--     ensure_installed = { "nil_ls" },
--   })

--   -- require("milkyvim.plugins.lsp.servers")
--   lsp_zero.setup_servers({ "lua_ls", "rust_analyzer", "nil_ls" })
-- end, 0)
