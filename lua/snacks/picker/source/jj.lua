local M = {}

---@return string?
local function jj_root()
  return vim.fs.root(vim.uv.cwd() or ".", ".jj")
end

---@param opts snacks.picker.Config
---@type snacks.picker.finder
function M.log(opts, ctx)
  local search = ctx.filter.search
  local revset = "all()"
  if search ~= "" and search:find("^r:") then
    revset = search:sub(3)
    if revset == "" then
      revset = "all()"
    end
  end

  local cwd = jj_root() or vim.uv.cwd() or "."
  ctx.picker:set_cwd(cwd)

  -- stylua: ignore
  local template = 'change_id.short(8) ++ "\\t" ++ commit_id.short(8) ++ "\\t" ++ author.email() ++ "\\t" ++ author.timestamp().format("%Y-%m-%d") ++ "\\t" ++ if(description, description.first_line(), "(empty)") ++ "\\t" ++ bookmarks ++ "\\n"'

  return require("snacks.picker.source.proc").proc(
    ctx:opts({
      cmd = "env",
      args = {
        "JJ_CONFIG=/dev/null",
        "jj",
        "log",
        "--no-pager",
        "--no-graph",
        "-T",
        template,
        "-r",
        revset,
      },
      cwd = cwd,
      notify = false,
      ---@param item snacks.picker.finder.Item
      transform = function(item)
        local parts = vim.split(item.text, "\t", { plain = true })
        if #parts < 5 then
          return false
        end
        item.cwd = cwd
        item.change_id = parts[1]
        item.commit = parts[2]
        item.author = parts[3]
        item.date = parts[4]
        item.msg = parts[5]
        item.bookmarks = parts[6] ~= "" and parts[6] or nil
      end,
    }),
    ctx
  )
end

---@param opts snacks.picker.Config
---@type snacks.picker.finder
function M.status(opts, ctx)
  local cwd = jj_root() or vim.uv.cwd() or "."
  ctx.picker:set_cwd(cwd)

  return require("snacks.picker.source.proc").proc(
    ctx:opts({
      cmd = "jj",
      args = { "status", "--no-pager" },
      cwd = cwd,
      ---@param item snacks.picker.finder.Item
      transform = function(item)
        local status, file = item.text:match("^([AMDC?]) (.+)$")
        if not status then
          return false
        end
        item.cwd = cwd
        item.status = status
        item.file = file
      end,
    }),
    ctx
  )
end

---@param opts snacks.picker.jj.diff.Config
---@type snacks.picker.finder
function M.diff(opts, ctx)
  opts = opts or {}
  local cwd = jj_root() or vim.uv.cwd() or "."
  ctx.picker:set_cwd(cwd)

  local args = { "JJ_CONFIG=/dev/null", "jj", "diff", "--no-pager", "--git" }

  if opts.rev then
    vim.list_extend(args, { "-r", opts.rev })
  end
  if opts.from and opts.to then
    vim.list_extend(args, { "--from", opts.from, "--to", opts.to })
  end

  if opts.current_file then
    local file = vim.api.nvim_buf_get_name(ctx.filter.current_buf)
    if file ~= "" then
      vim.list_extend(args, { "--", file })
    end
  end

  return require("snacks.picker.source.diff").diff(
    ctx:opts({
      cmd = "env",
      args = args,
      cwd = cwd,
    }),
    ctx
  )
end

---@param opts snacks.picker.Config
---@type snacks.picker.finder
function M.bookmarks(opts, ctx)
  local cwd = jj_root() or vim.uv.cwd() or "."
  ctx.picker:set_cwd(cwd)

  return require("snacks.picker.source.proc").proc(
    ctx:opts({
      cmd = "jj",
      args = { "bookmark", "list", "--no-pager", "--all" },
      cwd = cwd,
      ---@param item snacks.picker.finder.Item
      transform = function(item)
        local bookmark, change_id, commit, msg = item.text:match("^(%S+): (%S+) (%S+) (.*)$")
        if not bookmark then
          return false
        end
        item.cwd = cwd
        item.bookmark = bookmark
        item.change_id = change_id
        item.commit = commit
        item.msg = msg or ""
      end,
    }),
    ctx
  )
end

return M
