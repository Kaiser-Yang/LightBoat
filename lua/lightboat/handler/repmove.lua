local M = {}
local u = require('lightboat.util')

local todo_comment_available = u.plugin_available('todo-comments.nvim')
local function check()
  if not todo_comment_available then
    vim.notify('todo-comments.nvim is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end
-- HACK: Those two do not support vim.v.count
-- HACK: Those two will always return true
local function previous_todo()
  if not check() then return false end
  vim.schedule(function()
    vim.cmd("normal! m'")
    require('todo-comments').jump_prev()
  end)
  return true
end
local function next_todo()
  if not check() then return false end
  vim.schedule(function()
    vim.cmd("normal! m'")
    require('todo-comments').jump_next()
  end)
  return true
end

-- HACK:
-- Those below do not support vim.v.count
local function next_section_start()
  require('vim.treesitter._headings').jump({ count = 1 })
  return true
end
local function previous_section_start()
  require('vim.treesitter._headings').jump({ count = -1 })
  return true
end
-- TODO:
-- Find a better way to do this
local previous_section_end = previous_section_start
local next_section_end = next_section_start
local go_to = require('lightboat.handler.treesitter').go_to
local indent_goto = require('lightboat.handler.blink_indent').indent_goto

local urp = {}
function M.repmove_wrap(previous, next, idx, comma, semicolon)
  local res = u.ensure_repmove(previous, next, comma, semicolon, urp)
  if idx == 1 or idx == 2 then
    return res[idx]
  else
    return res
  end
end

-- HACK:
-- Those below can not cycle
local function next_loop_start() return go_to('next', 'start', '@loop.outer') end
local function next_loop_end()
  if vim.fn.mode('1'):sub(1, 2) == 'no' then return go_to('next', 'end', '@loop.inner') end
  return go_to('next', 'end', '@loop.outer')
end
local function next_class_start() return go_to('next', 'start', '@class.outer') end
local function next_class_end() return go_to('next', 'end', '@class.outer') end
local function next_block_start() return go_to('next', 'start', '@block.outer') end
local function next_block_end()
  if vim.fn.mode('1'):sub(1, 2) == 'no' then return go_to('next', 'end', '@block.inner') end
  return go_to('next', 'end', '@block.outer')
end
local function next_return_start() return go_to('next', 'start', '@return.outer') end
local function next_return_end() return go_to('next', 'end', '@return.outer') end
local function next_conditional_start() return go_to('next', 'start', '@conditional.outer') end
local function next_conditional_end() return go_to('next', 'end', '@conditional.outer') end
local function next_function_start() return go_to('next', 'start', '@function.outer') end
local function next_function_end()
  if vim.fn.mode('1'):sub(1, 2) == 'no' then return go_to('next', 'end', '@function.inner') end
  return go_to('next', 'end', '@function.outer')
end
local function next_parameter_start() return go_to('next', 'start', '@parameter.outer') end
local function next_parameter_end() return go_to('next', 'end', '@parameter.outer') end
local function next_statement_start() return go_to('next', 'start', '@statement.outer') end
local function next_statement_end() return go_to('next', 'end', '@statement.outer') end
local function next_call_start() return go_to('next', 'start', '@call.outer') end
local function next_call_end() return go_to('next', 'end', '@call.outer') end
local function previous_loop_start()
  if vim.fn.mode('1'):sub(1, 2) == 'no' then return go_to('previous', 'start', '@loop.inner') end
  return go_to('previous', 'start', '@loop.outer')
end
local function previous_loop_end() return go_to('previous', 'end', '@loop.outer') end
local function previous_class_start() return go_to('previous', 'start', '@class.outer') end
local function previous_class_end() return go_to('previous', 'end', '@class.outer') end
local function previous_block_start()
  if vim.fn.mode('1'):sub(1, 2) == 'no' then return go_to('previous', 'start', '@block.inner') end
  return go_to('previous', 'start', '@block.outer')
end
local function previous_block_end() return go_to('previous', 'end', '@block.outer') end
local function previous_return_start() return go_to('previous', 'start', '@return.outer') end
local function previous_return_end() return go_to('previous', 'end', '@return.outer') end
local function previous_conditional_start() return go_to('previous', 'start', '@conditional.outer') end
local function previous_conditional_end() return go_to('previous', 'end', '@conditional.outer') end
local function previous_function_start()
  if vim.fn.mode('1'):sub(1, 2) == 'no' then return go_to('previous', 'start', '@function.inner') end
  return go_to('previous', 'start', '@function.outer')
end
local function previous_function_end() return go_to('previous', 'end', '@function.outer') end
local function previous_parameter_start() return go_to('previous', 'start', '@parameter.outer') end
local function previous_parameter_end() return go_to('previous', 'end', '@parameter.outer') end
local function previous_statement_start() return go_to('previous', 'start', '@statement.outer') end
local function previous_statement_end() return go_to('previous', 'end', '@statement.outer') end
local function previous_call_start() return go_to('previous', 'start', '@call.outer') end
local function previous_call_end() return go_to('previous', 'end', '@call.outer') end

local function indent_top() return indent_goto('top') end
local function indent_bottom() return indent_goto('bottom') end

local repmove_available = u.plugin_available('repmove.nvim')
function M.indent_top() return u.ensure_repmove(indent_top, indent_bottom)[1]() end
function M.indent_bottom() return u.ensure_repmove(indent_top, indent_bottom)[2]() end

-- stylua: ignore start
function M.comma() if not repmove_available then return ',' end return require('repmove').comma() end
function M.semicolon() if not repmove_available then return ';' end return require('repmove').semicolon() end
function M.F() return u.ensure_repmove('F', 'f', ',', ';')[1]() end
function M.f() return u.ensure_repmove('F', 'f', ',', ';')[2]() end
function M.T() return u.ensure_repmove('T', 't', ',', ';')[1]() end
function M.t() return u.ensure_repmove('T', 't', ',', ';')[2]() end
function M.next_todo() return u.ensure_repmove(previous_todo, next_todo)[2]() end
function M.next_misspelled() return u.ensure_repmove('[s', ']s')[2]() end
function M.next_section_start() return u.ensure_repmove(previous_section_start, next_section_start)[2]() end
function M.next_section_end() return u.ensure_repmove(previous_section_end, next_section_end)[2]() end
function M.next_function_start() return u.ensure_repmove(previous_function_start, next_function_start)[2]() end
function M.next_function_end() return u.ensure_repmove(previous_function_end, next_function_end)[2]() end
function M.next_class_start() return u.ensure_repmove(previous_class_start, next_class_start)[2]() end
function M.next_class_end() return u.ensure_repmove(previous_class_end, next_class_end)[2]() end
function M.next_block_end() return u.ensure_repmove(previous_block_end, next_block_end)[2]() end
function M.next_block_start() return u.ensure_repmove(previous_block_start, next_block_start)[2]() end
function M.next_loop_start() return u.ensure_repmove(previous_loop_start, next_loop_start)[2]() end
function M.next_loop_end() return u.ensure_repmove(previous_loop_end, next_loop_end)[2]() end
function M.next_return_start() return u.ensure_repmove(previous_return_start, next_return_start)[2]() end
function M.next_return_end() return u.ensure_repmove(previous_return_end, next_return_end)[2]() end
function M.next_parameter_start() return u.ensure_repmove(previous_parameter_start, next_parameter_start)[2]() end
function M.next_parameter_end() return u.ensure_repmove(previous_parameter_end, next_parameter_end)[2]() end
function M.next_conditional_start() return u.ensure_repmove(previous_conditional_start, next_conditional_start)[2]() end
function M.next_conditional_end() return u.ensure_repmove(previous_conditional_end, next_conditional_end)[2]() end
function M.next_statement_start() return u.ensure_repmove(previous_statement_start, next_statement_start)[2]() end
function M.next_statement_end() return u.ensure_repmove(previous_statement_end, next_statement_end)[2]() end
function M.next_call_start() return u.ensure_repmove(previous_call_start, next_call_start)[2]() end
function M.next_call_end() return u.ensure_repmove(previous_call_end, next_call_end)[2]() end
function M.previous_todo() return u.ensure_repmove(previous_todo, next_todo)[1]() end
function M.previous_misspelled() return u.ensure_repmove('[s', ']s')[1]() end
function M.previous_section_start() return u.ensure_repmove(previous_section_start, next_section_start)[1]() end
function M.previous_section_end() return u.ensure_repmove(previous_section_end, next_section_end)[1]() end
function M.previous_function_start() return u.ensure_repmove(previous_function_start, next_function_start)[1]() end
function M.previous_function_end() return u.ensure_repmove(previous_function_end, next_function_end)[1]() end
function M.previous_class_start() return u.ensure_repmove(previous_class_start, next_class_start)[1]() end
function M.previous_class_end() return u.ensure_repmove(previous_class_end, next_class_end)[1]() end
function M.previous_block_start() return u.ensure_repmove(previous_block_start, next_block_start)[1]() end
function M.previous_block_end() return u.ensure_repmove(previous_block_end, next_block_end)[1]() end
function M.previous_loop_start() return u.ensure_repmove(previous_loop_start, next_loop_start)[1]() end
function M.previous_loop_end() return u.ensure_repmove(previous_loop_end, next_loop_end)[1]() end
function M.previous_return_start() return u.ensure_repmove(previous_return_start, next_return_start)[1]() end
function M.previous_return_end() return u.ensure_repmove(previous_return_end, next_return_end)[1]() end
function M.previous_parameter_start() return u.ensure_repmove(previous_parameter_start, next_parameter_start)[1]() end
function M.previous_parameter_end() return u.ensure_repmove(previous_parameter_end, next_parameter_end)[1]() end
function M.previous_conditional_start() return u.ensure_repmove(previous_conditional_start, next_conditional_start)[1]() end
function M.previous_conditional_end() return u.ensure_repmove(previous_conditional_end, next_conditional_end)[1]() end
function M.previous_statement_start() return u.ensure_repmove(previous_statement_start, next_statement_start)[1]() end
function M.previous_statement_end() return u.ensure_repmove(previous_statement_end, next_statement_end)[1]() end
function M.previous_call_start() return u.ensure_repmove(previous_call_start, next_call_start)[1]() end
function M.previous_call_end() return u.ensure_repmove(previous_call_end, next_call_end)[1]() end
-- stylua: ignore end

return M
