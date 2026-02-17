local u = require('lightboat.util')
local M = {}
local blink_indent_available = u.plugin_available('blink.indent')

-- BUG:
-- https://github.com/saghen/blink.indent/issues/45
function M.inside_indent()
  if not blink_indent_available then return false end
  require('blink.indent.motion').textobject()()
  return true
end

function M.around_indent()
  if not blink_indent_available then return false end
  local maps = require('blink.indent.config').mappings
  require('blink.indent.motion').textobject({ border = maps.border })()
  return true
end
-- BUG:
-- https://github.com/saghen/blink.indent/issues/46
function M.indent_goto(direction)
  if not blink_indent_available then return false end
  require('blink.indent.motion').operator(direction, vim.fn.mode('1') == 'n')()
  return true
end

function M.toggle_indent_line()
  if not blink_indent_available then return false end
  local indent = require('blink.indent')
  local status = indent.is_enabled() == false
  u.toggle_notify('Indent Line', status, { title = 'Blink Indent' })
  indent.enable(status)
  return true
end
return M
