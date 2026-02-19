local M = {}
local u = require('lightboat.util')

M = vim.tbl_deep_extend('error', M, require('lightboat.handler.builtin'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.completion'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.markdown'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.pair'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.surround'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.treesitter'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.repmove'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.blink_indent'))
M = vim.tbl_deep_extend('error', M, require('lightboat.handler.telescope'))

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

return M
