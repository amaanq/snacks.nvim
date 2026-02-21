---@class snacks.jjui
---@overload fun(opts?: snacks.jjui.Config): snacks.win
local M = setmetatable({}, {
  __call = function(t, ...)
    return t.open(...)
  end,
})

M.meta = {
  desc = "Open jjui (Jujutsu TUI) in a float",
}

---@class snacks.jjui.Config: snacks.terminal.Opts
---@field args? string[]
local defaults = {
  win = {
    style = "jjui",
  },
}

Snacks.config.style("jjui", {
  position = "float",
  backdrop = 60,
  height = 0.85,
  width = 0.85,
  border = "double",
})

--- Opens jjui
---@param opts? snacks.jjui.Config
function M.open(opts)
  ---@type snacks.jjui.Config
  opts = Snacks.config.get("jjui", defaults, opts)

  local cmd = { "jjui" }
  vim.list_extend(cmd, opts.args or {})

  return Snacks.terminal(cmd, opts)
end

---@private
function M.health()
  local ok = vim.fn.executable("jjui") == 1
  Snacks.health[ok and "ok" or "error"](("{jjui} %sinstalled"):format(ok and "" or "not "))
end

return M
