local M = {}
local u = require('lightboat.util')

M = vim.tbl_deep_extend('error', M, require('lightboat.handler.builtin'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.completion'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.markdown'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.pair'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.treesitter'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.repmove'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.blink_indent'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.telescope'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.git'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.nvim_tree'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.dap'))

local conform_available = u.plugin_available('conform.nvim')
function M.async_format()
  if not conform_available then
    vim.notify('conform.nvim is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  local res = require('conform').format({ async = true })
  if res ~= nil then return res end
  return true
end

local first_to_second = {
  top = 'bottom',
  bottom = 'top',
  left = 'right',
  right = 'left',
}
--- @param border 'top' | 'bottom' | 'left' | 'right'
--- @param reverse boolean
--- @param abs_delta integer
--- @param first 'top' | 'bottom' | 'left' | 'right' | nil
function M.resize_wrap(border, reverse, abs_delta, first)
  abs_delta = abs_delta or 3
  first = first or vim.tbl_contains({ 'left', 'right' }, border) and 'right' or 'top'
  local second = first_to_second[first]
  local delta = (border == first) and abs_delta or -abs_delta
  return function()
    if not u.plugin_available('win-resizer.nvim') then
      vim.notify('win-resizer.nvim is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    end
    local resize = require('win.resizer').resize
    local actual_delta = delta * vim.v.count1
    if reverse then
      return resize(0, second, -actual_delta, true)
        or resize(0, first, actual_delta, true)
        or resize(0, second, -actual_delta, false)
        or resize(0, first, actual_delta, false)
    else
      return resize(0, first, actual_delta, true)
        or resize(0, second, -actual_delta, true)
        or resize(0, first, actual_delta, false)
        or resize(0, second, -actual_delta, false)
    end
  end
end

return M
