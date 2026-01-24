local action = require('lightboat.action')
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
function M.del(mode, lhs, opts) pcall(vim.keymap.del, mode, lhs, opts) end

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
  res.prev = nil
  res.key = nil
  res.opts = nil
  return res
end

function M.prev_operation_wrap(prev, cur)
  local util = require('lightboat.util')
  prev = util.ensure_list(prev)
  if #prev == 0 then return cur end
  return function(...)
    local ret
    prev = util.ensure_list(prev)
    for _, v in ipairs(prev) do
      if action[v] then
        ret = util.get(action[v], ...)
      else
        ret = util.get(v, ...)
      end
      if ret then return ret end
    end
    return util.get(cur, ...)
  end
end

function M.get_lazy_keys(operation, keys)
  if not keys or not operation then return {} end
  local res = {}
  for k, v in pairs(keys) do
    if not v or not operation[k] then goto continue end
    local key = M.convert(v, true)
    key[2] = M.prev_operation_wrap(v.prev, operation[k])
    table.insert(res, key)
    ::continue::
  end
  return res
end

function M.set_keys(operation, keys)
  local util = require('lightboat.util')
  if not keys or not operation then return end
  for k, v in pairs(keys) do
    if not v or not operation[k] then goto continue end
    for _, key in pairs(util.ensure_list(v.key)) do
      M.set(v.mode, key, M.prev_operation_wrap(v.prev, operation[k]), M.convert(v))
    end
    ::continue::
  end
end

function M.clear_keys(operation, keys)
  local util = require('lightboat.util')
  if not keys or not operation then return end
  for k, v in pairs(keys) do
    if not v or not operation[k] then goto continue end
    for _, key in pairs(util.ensure_list(v.key)) do
      M.del(v.mode or 'n', key, { buffer = v.buffer })
    end
    ::continue::
  end
end

return M
