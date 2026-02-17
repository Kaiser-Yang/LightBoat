local u = require('lightboat.util')
local M = {}

local last_count = 1
local surround_available = u.plugin_available('nvim-surround')
local function hack(suffix, is_S)
  if not surround_available then return false end
  suffix = suffix or ''
  local op = vim.v.operator
  if op ~= 'g@' then last_count = vim.v.count1 end
  local res
  if op == 'y' then
    if is_S then
      -- suffix is ignored when is_S this will make "yS" behaviour like "ys$"
      res = M['surround_normal']
    else
      res = M['surround_normal' .. suffix]
    end
  elseif op == 'd' then
    res = M['surround_delete' .. suffix]
  elseif op == 'c' then
    res = M['surround_change' .. suffix]
  elseif op == 'g@' and vim.o.operatorfunc:find('nvim%-surround') then
    res = M['surround_normal_current' .. suffix]
  end
  if not res then return false end
  if op ~= 'g@' then
    return '<esc>' .. tostring(vim.v.count1) .. res() .. (is_S and '$' or '')
  else
    return '<esc>' .. tostring(last_count) .. res()
  end
end

function M.surround_normal()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal)'
end
function M.surround_normal_current()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal-cur)'
end
function M.surround_normal_line()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal-line)'
end
function M.surround_normal_current_line()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal-cur-line)'
end
function M.surround_insert()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-insert)'
end
function M.surround_insert_line()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-insert-line)'
end
function M.surround_delete()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-delete)'
end
function M.surround_change()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-change)'
end
function M.surround_change_line()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-change-line)'
end
function M.surround_visual()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-visual)'
end
function M.surround_visual_line()
  if not surround_available then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-visual-line)'
end
function M.hack_wrap(suffix, is_S)
  return function() return hack(suffix, is_S) end
end

return M
