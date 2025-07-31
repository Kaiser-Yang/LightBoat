local M = {}

--- Set a map
--- @param mode string|string[]?
--- @param lhs string
--- @param rhs string|function
--- @param opts? vim.keymap.set.Opts default: { silent = true, remap = false, nowait = true }
function M.set(mode, lhs, rhs, opts)
  opts = vim.tbl_extend('force', { silent = true, remap = false, nowait = true }, opts or {})
  mode = mode or 'n'
  vim.keymap.set(mode, lhs, rhs, opts)
end

--- Delete a map by lhs
--- @param mode string|string[] the mode to delete
--- @param lhs string the key to delete
--- @param opts? { buffer: integer|boolean }
function M.del(mode, lhs, opts) vim.keymap.del(mode, lhs, opts) end

--- @param keys string
--- @param mode string
function M.feedkeys(keys, mode)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, true, true)
  vim.api.nvim_feedkeys(termcodes, mode, false)
end

--- @param keys string
--- @return string
function M.termcodes(keys) return vim.api.nvim_replace_termcodes(keys, true, true, true) end

--- @param lazy boolean?
--- @return vim.keymap.set.Opts
function M.convert(opts, lazy)
  local res = vim.deepcopy(opts)
  if not lazy then
    res.mode = nil
  else
    res[1] = res.key
  end
  res.key = nil
  res.opts = nil
  return res
end

function M.get_lazy_keys(operation, keys)
  local res = {}
  for k, v in pairs(keys) do
    if not v or not operation[k] then goto continue end
    local key = M.convert(v, true)
    key[2] = operation[k]
    table.insert(res, key)
    ::continue::
  end
  return res
end

return M
