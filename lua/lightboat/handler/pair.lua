local u = require('lightboat.util')
local M = {}

local last_count = 1
local surround_available = u.plugin_available('nvim-surround')
local function check()
  if not surround_available then
    vim.notify('nvim-surround is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end
local l = {}
function l.surround_normal()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal)'
end
function l.surround_normal_current()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal-cur)'
end
function l.surround_normal_line()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal-line)'
end
function l.surround_normal_current_line()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal-cur-line)'
end
function l.surround_insert()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-insert)'
end
function l.surround_insert_line()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-insert-line)'
end
function l.surround_delete()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-delete)'
end
function l.surround_change()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-change)'
end
function l.surround_change_line()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-change-line)'
end
local function hack(suffix)
  if not check() then return false end
  suffix = suffix or ''
  local op = vim.v.operator
  if op ~= 'g@' then last_count = vim.v.count1 end
  local res
  if op == 'y' then
    res = l['surround_normal' .. suffix]
  elseif op == 'd' then
    res = l['surround_delete' .. suffix]
  elseif op == 'c' then
    res = l['surround_change' .. suffix]
  elseif op == 'g@' and vim.o.operatorfunc:find('nvim%-surround') then
    res = l['surround_normal_current' .. suffix]
  end
  if not res then return false end
  local key = (op == 'g@' and last_count or vim.v.count1) .. res()
  vim.schedule_wrap(u.key.feedkeys)(key, 'n')
  return '<esc>'
end

function M.surround_visual()
  if not check() then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-visual)'
end
function M.surround_visual_line()
  if not check() then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-visual-line)'
end
function M.hack_wrap(suffix)
  return function() return hack(suffix) end
end

return M
