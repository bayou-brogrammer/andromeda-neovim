local Utils = require("milkyvim.utils")

---@class milkyvim.utils.telescope.opts
---@field cwd? string|boolean
---@field show_untracked? boolean

---@class milkyvim.utils.telescope
---@overload fun(builtin:string, opts?:milkyvim.utils.telescope.opts)
local M = setmetatable({}, {
  __call = function(m, ...)
    return m.telescope(...)
  end,
})

----------------
-- Config Files
----------------
function M.config_files()
  return Utils.telescope("find_files", { cwd = vim.fn.stdpath("config") })
end

-- this will return a function that calls telescope.
-- cwd will default to milkyvim.util.get_root
-- for `files`, git_files or find_files will be chosen depending on .git
---@param builtin string
---@param opts? milkyvim.utils.telescope.opts
function M.telescope(builtin, opts)
  local params = { builtin = builtin, opts = opts }

  return function()
    builtin = params.builtin

    opts = params.opts
    opts = vim.tbl_deep_extend("force", { cwd = Utils.root() }, opts or {}) --[[@as milkyvim.utils.telescope.opts]]

    ---------
    -- FILES
    ---------
    if builtin == "files" then
      if vim.loop.fs_stat((opts.cwd or vim.loop.cwd()) .. "/.git") then
        opts.show_untracked = true
        builtin = "git_files"
      else
        builtin = "find_files"
      end
    end

    ---------
    -- CWD
    ---------
    if opts.cwd and opts.cwd ~= vim.loop.cwd() then
      ---@diagnostic disable-next-line: inject-field
      opts.attach_mappings = function(_, map)
        map("i", "<a-c>", function()
          local action_state = require("telescope.actions.state")
          local line = action_state.get_current_line()
          M.telescope(
            params.builtin,
            vim.tbl_deep_extend("force", {}, params.opts or {}, { cwd = false, default_text = line })
          )()
        end)
        return true
      end
    end

    require("telescope.builtin")[builtin](opts)
  end
end

return M
