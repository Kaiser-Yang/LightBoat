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

--- @param border 'top' | 'bottom' | 'left' | 'right'
function M.resize_wrap(border, reverse, abs_delta, first_left_or_right, first_top_or_bottom)
  first_left_or_right = first_left_or_right or 'right'
  first_top_or_bottom = first_top_or_bottom or 'top'
  local second_left_or_right = first_left_or_right == 'right' and 'left' or 'right'
  local second_top_or_bottom = first_top_or_bottom == 'bottom' and 'top' or 'bottom'
  abs_delta = abs_delta or 3
  local delta = (border == first_left_or_right or border == first_top_or_bottom) and abs_delta or -abs_delta
  local first = (border == first_left_or_right or border == second_left_or_right) and first_left_or_right
    or first_top_or_bottom
  local second = first == first_left_or_right and second_left_or_right or second_top_or_bottom
  return function()
    if not u.plugin_available('win-resizer.nvim') then
      vim.notify('win-resizer.nvim is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    end
    local resize = require('win.resizer').resize
    local actual_delta = delta * vim.v.count1
    if reverse then
      return resize(0, second, -actual_delta, false)
        or resize(0, first, actual_delta, false)
        or resize(0, second, -actual_delta, true)
        or resize(0, first, actual_delta, true)
    else
      return resize(0, first, actual_delta, true)
        or resize(0, second, -actual_delta, true)
        or resize(0, first, actual_delta, false)
        or resize(0, second, -actual_delta, false)
    end
  end
end

return M
