local M = {}
local u = require('lightboat.util')

M = vim.tbl_deep_extend('error', M, require('lightboat.handler.builtin'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.completion'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.markdown'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.pair'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.picker'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.surround'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.treesitter'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.repmove'))

local blink_indent_available = u.plugin_available('blink.indent')
M.toggle_blink_indent = function()
  if not blink_indent_available then return false end
  local indent = require('blink.indent')
  local status = indent.is_enabled() == false
  u.toggle_notify('Indent Line', status, { title = 'Blink Indent' })
  indent.enable(status)
  return true
end

local conform_available = u.plugin_available('conform.nvim')
function M.async_format()
  if not conform_available then return false end
  local res = require('conform').format({ async = true })
  if res ~= nil then return res end
  return true
end

return M
