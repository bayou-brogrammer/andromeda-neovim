local Event = require("lazy.core.handler.event")
local Plugin = require("lazy.core.plugin")
local Utils = require("milkyvim.utils")

---@class milkyvim.utils.plugin
local M = {}

M.loading = {}

---------------------
-- * Plugin setup * -
---------------------

---@alias MilkyPluginOpts table|fun(self:MilkyPlugin, opts:table):table?

-- * Milky {Keys} * --
---@class MilkyKeyBase
---@field desc? string
---@field noremap? boolean
---@field remap? boolean
---@field expr? boolean
---@field nowait? boolean
---@field ft? string|string[]

---@class MilkyKeySpec: MilkyKeyBase
---@field [1] string lhs
---@field [2]? string|fun()|false rhs
---@field mode? string|string[]

---@class MilkyKeys: MilkyKeyBase
---@field lhs string lhs
---@field rhs? string|fun() rhs
---@field mode? string
---@field id string
---@field name string

-- * Milky {Plugin} * --
---@class MilkyPluginBase
---@field [1] string?
---@field name string
---@field main? string Entry module that has setup & deactivate

---@class MilkyPluginState
---@field loaded? {[string]:string}|{time:number}

---@class MilkyPluginHandlers
---@field keys? table<string,MilkyKeys>

---@class MilkyPluginHooks
---@field opts? MilkyPluginOpts
---@field init? fun(self:MilkyPlugin) Will always be run
---@field config? fun(self:MilkyPlugin, opts:table)|true Will be executed when loading the plugin

---@class MilkyPlugin: MilkyPluginBase,MilkyPluginHandlers,MilkyPluginHooks
---@field dependencies? string[]
---@field _? MilkyPluginState

-- * Milky {Plugin Spec} * --

---@class MilkyPluginSpecHandlers
---@field keys? string|string[]|MilkyKeySpec[]|fun(self:MilkyPlugin, keys:string[]):(string|MilkyKeys)[]
---@field module? false

---@class MilkyPluginSpec: MilkyPluginBase,MilkyPluginSpecHandlers,MilkyPluginHooks
---@field dependencies? string|string[]|MilkyPluginSpec[]

---@class MilkySpecImport
---@field import string spec module to import
---@field enabled? boolean|(fun():boolean)
---@field cond? boolean|(fun():boolean)

---@alias MilkySpec string|MilkyPluginSpec|MilkySpecImport|MilkySpec[]

-- Load a plugin
---@param plugins string|MilkySpec|string[]|MilkySpec[]
function M.load(plugins)
  plugins = (type(plugins) == "string" or plugins.name) and { plugins } or plugins
  ---@cast plugins (string|MilkySpec)[]

  for _, plugin in pairs(plugins) do
    if type(plugin) == "string" then
      plugin = { plugin }
    end

    ---@cast plugin MilkyPlugin
    plugin.name = plugin.name or plugin[1]
    plugin.main = plugin.main or plugin.name
    plugin._ = plugin._ or {}

    if plugin and not plugin._.loaded then
      M._load(plugin)
    end
  end
end

---@param plugin MilkyPlugin
function M._load(plugin)
  plugin.name = plugin.name or plugin[1]
  plugin.main = plugin.main or plugin.name
  plugin._.loaded = {}

  if #M.loading > 0 then
    plugin._.loaded.plugin = M.loading[#M.loading].name
  end

  table.insert(M.loading, plugin)
  Utils.track({ plugin = plugin.name })

  if plugin.dependencies then
    M.load(plugin.dependencies)
  end

  if plugin.config or plugin.opts then
    M.config(plugin)
  end

  -- Load keymaps
  if plugin.keys ~= nil then
    Utils.load_keymaps(plugin.keys)
  end

  plugin._.loaded.time = Utils.track().time
  table.remove(M.loading)

  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", { pattern = "LazyLoad", modeline = false, data = plugin.name })
    vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
  end)
end

--- runs plugin config
---@param plugin MilkyPlugin
function M.config(plugin)
  local fn
  if type(plugin.config) == "function" then
    fn = function()
      local opts = Plugin.values(plugin, "opts", false)
      plugin.config(plugin, opts)
    end
  else
    fn = function()
      local opts = Plugin.values(plugin, "opts", false)
      require(plugin.main).setup(opts)
    end
  end

  -- If the plugin has a config function, run it
  fn()
end

---------------------
-- * Lazy loading * -
---------------------

M.use_lazy_file = true
M.lazy_file_events = { "BufReadPost", "BufNewFile", "BufWritePre" }

function M.setup()
  M.lazy_file()
end

-- Properly load file based plugins without blocking the UI
function M.lazy_file()
  M.use_lazy_file = M.use_lazy_file and vim.fn.argc(-1) > 0

  -- Add support for the LazyFile event
  if M.use_lazy_file then
    -- We'll handle delayed execution of events ourselves
    Event.mappings.LazyFile = { id = "LazyFile", event = "User", pattern = "LazyFile" }
    Event.mappings["User LazyFile"] = Event.mappings.LazyFile
  else
    -- Don't delay execution of LazyFile events, but let lazy know about the mapping
    Event.mappings.LazyFile = { id = "LazyFile", event = { "BufReadPost", "BufNewFile", "BufWritePre" } }
    Event.mappings["User LazyFile"] = Event.mappings.LazyFile
    return
  end

  local events = {} ---@type {event: string, buf: number, data?: any}[]

  local done = false
  local function load()
    if #events == 0 or done then
      return
    end
    done = true
    vim.api.nvim_del_augroup_by_name("lazy_file")

    ---@type table<string,string[]>
    local skips = {}
    for _, event in ipairs(events) do
      skips[event.event] = skips[event.event] or Event.get_augroups(event.event)
    end

    vim.api.nvim_exec_autocmds("User", { pattern = "LazyFile", modeline = false })
    for _, event in ipairs(events) do
      if vim.api.nvim_buf_is_valid(event.buf) then
        Event.trigger({
          event = event.event,
          exclude = skips[event.event],
          data = event.data,
          buf = event.buf,
        })
        if vim.bo[event.buf].filetype then
          Event.trigger({
            event = "FileType",
            buf = event.buf,
          })
        end
      end
    end

    vim.api.nvim_exec_autocmds("CursorMoved", { modeline = false })
    events = {}
  end

  -- schedule wrap so that nested autocmds are executed
  -- and the UI can continue rendering without blocking
  load = vim.schedule_wrap(load)

  vim.api.nvim_create_autocmd(M.lazy_file_events, {
    group = vim.api.nvim_create_augroup("lazy_file", { clear = true }),
    callback = function(event)
      table.insert(events, event)
      load()
    end,
  })
end

return M
