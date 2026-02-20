local u = require('lightboat.util')
local M = {}
local check_conflict = function()
  if not u.plugin_available('resolve.nvim') then
    vim.notify('resolve.nvim is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end
local check = function()
  if not u.plugin_available('gitsigns.nvim') then
    vim.notify('gitsigns.nvim is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end
M._previous_conflict = function()
  if not check_conflict() then return false end
  require('resolve').prev_conflict()
  return true
end
M._next_conflict = function()
  if not check_conflict() then return false end
  require('resolve').next_conflict()
  return true
end
M._previous_hunk = function()
  if not check() then return false end
  require('gitsigns').nav_hunk('prev')
  return true
end
M._next_hunk = function()
  if not check() then return false end
  require('gitsigns').nav_hunk('next')
  return true
end

M.stage_selection = function()
  if not check() then return false end
  require('gitsigns').stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
  return true
end
M.reset_selection = function()
  if not check() then return false end
  require('gitsigns').reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
  return true
end
M.quickfix_all_hunk = function()
  if not check() then return false end
  require('gitsigns').setqflist('all')
  return true
end
M.toggle_current_line_blame = function()
  if not check() then return false end
  u.toggle_notify('Current Line Blame', require('gitsigns').toggle_current_line_blame(), { title = 'Git Sign' })
  return true
end
M.toggle_word_diff = function()
  if not check() then return false end
  u.toggle_notify('Word Diff', require('gitsigns').toggle_word_diff(), { title = 'Git Sign' })
  return true
end
M.toggle_signs = function()
  if not check() then return false end
  u.toggle_notify('Signs', require('gitsigns').toggle_signs(), { title = 'Git Sign' })
  return true
end
M.toggle_numhl = function()
  if not check() then return false end
  u.toggle_notify('Line Number Highlight', require('gitsigns').toggle_numhl(), { title = 'Git Sign' })
  return true
end
M.toggle_linehl = function()
  if not check() then return false end
  u.toggle_notify('Line Highlight', require('gitsigns').toggle_linehl(), { title = 'Git Sign' })
  return true
end
M.toggle_deleted = function()
  if not check() then return false end
  u.toggle_notify('Deleted', require('gitsigns').toggle_deleted(), { title = 'Git Sign' })
  return true
end
M.diff_this = function()
  if not check() then return false end
  require('gitsigns').diffthis('~')
  return true
end
return M
