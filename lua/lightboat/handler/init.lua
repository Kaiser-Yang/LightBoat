local util = require('lightboat.util')

--- @param n integer
--- @return string
function M.markdown_title(n) return '<c-g>u<bs>' .. string.rep('#', n) .. ' ' end
M.markdown_separate_line = '<c-g>u<bs>---<cr><cr>'
M.markdown_math_inline = '<c-g>u<bs>$  $<++>' .. string.rep('<c-g>U<left>', 6)
M.markdown_math_inline_2 = '<c-g>u<bs>$$  $$<++>' .. string.rep('<c-g>U<left>', 7)
M.markdown_code_line = '<c-g>u<bs>``<++>' .. string.rep('<c-g>U<left>', 5)
M.markdown_todo = '<c-g>u<bs>- [ ] '
M.markdown_link = '<c-g>u<bs>[](<++>)<++>' .. string.rep('<c-g>U<left>', 11)
M.markdown_bold = '<c-g>u<bs>****<++>' .. string.rep('<c-g>U<left>', 6)
M.markdown_delete_line = '<c-g>u<bs>~~~~<++>' .. string.rep('<c-g>U<left>', 6)
M.markdown_italic = '<c-g>u<bs>**<++>' .. string.rep('<c-g>U<left>', 5)
M.markdown_math_block = '<c-g>u<bs>$$<cr><cr>$$<cr><cr><++>' .. string.rep('<up>', 3) .. string.rep('<right>', 2)
M.markdown_code_block = '<c-g>u<bs>```<cr><cr>```<cr><cr><++>' .. string.rep('<up>', 4)
function M.markdown_goto_placeholder()
  local pattern = '<++>'
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local cur_buf = vim.api.nvim_get_current_buf()
  local row_end = math.min(row + 100, vim.api.nvim_buf_line_count(cur_buf))
  local match = vim.fn.matchbufline(cur_buf, pattern, row, row_end)[1]
  if match then
    if match.lnum == row then
      return '<bs>'
        .. string.rep('<c-g>U<right>', vim.fn.strchars(vim.api.nvim_get_current_line():sub(col + 1, match.byteidx)))
        .. string.rep('<del>', #pattern)
    else
      vim.schedule(function()
        vim.api.nvim_win_set_cursor(0, { match.lnum, match.byteidx })
        util.key.feedkeys(string.rep('<del>', #pattern), 'n')
      end)
      return '<c-g>u<bs>'
    end
  else
    return 'f'
  end
end

--- @param direction 'next'|'previous'
--- @param position 'start'|'end'
local function go_to(direction, position, query_string)
  require('nvim-treesitter-textobjects.move')['goto_' .. direction .. '_' .. position](query_string)
  -- HACK:
  -- We do not know if the operation is successful or not, so just return true
  return true
end

local function select(query_string, query_group)
  require('nvim-treesitter-textobjects.select').select_textobject(query_string, query_group)
  -- HACK:
  -- We do not know if the operation is successful or not, so just return true
  return true
end

--- @param direction 'next'|'previous'
local function swap(direction, query_string)
  require('nvim-treesitter-textobjects.swap')['swap_' .. direction](query_string)
  -- HACK:
  -- We do not know if the operation is successful or not, so just return true
  return true
end

--- @type table<string, function>
local repmove = {}
--- @param previous string|function
--- @return table<function>
local function ensure_repmove(previous, next)
  if not repmove[previous] or not repmove[next] then
    repmove[previous], repmove[next] = require('repmove').make(previous, next)
  end
  return { repmove[previous], repmove[next] }
end

--- Copied from nvim-treesitter-textobjects.select
--- @param start_row integer 0 indexed
--- @param start_col integer 0 indexed
--- @param end_row integer 0 indexed
--- @param end_col integer 0 indexed, exclusive
--- @param selection_mode string
local function update_selection(start_row, start_col, end_row, end_col, selection_mode)
  selection_mode = selection_mode or 'v'

  -- enter visual mode if normal or operator-pending (no) mode
  -- Why? According to https://learnvimscriptthehardway.stevelosh.com/chapters/15.html
  --   If your operator-pending mapping ends with some text visually selected, Vim will operate on that text.
  --   Otherwise, Vim will operate on the text between the original cursor position and the new position.
  local mode = vim.api.nvim_get_mode()
  selection_mode = vim.api.nvim_replace_termcodes(selection_mode, true, true, true)
  if mode.mode ~= selection_mode then vim.cmd.normal({ selection_mode, bang = true }) end

  -- end positions with `col=0` mean "up to the end of the previous line, including the newline character"
  if end_col == 0 then
    end_row = end_row - 1
    -- +1 is needed because we are interpreting `end_col` to be exclusive afterwards
    end_col = #vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, true)[1] + 1
  end

  local end_col_offset = 1
  if selection_mode == 'v' and vim.o.selection == 'exclusive' then end_col_offset = 0 end
  end_col = end_col - end_col_offset

  -- Position is 1, 0 indexed.
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  vim.cmd('normal! o')
  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
end

function M.around_file()
  update_selection(0, 0, vim.api.nvim_buf_line_count(0), 0, 'V')
  return true
end
-- stylua: ignore start
-- HACK:
-- This below can not cycle
function M.next_loop_start() return go_to('next', 'start', '@loop.outer') end
function M.next_class_start() return go_to('next', 'start', '@class.outer') end
function M.next_block_start() return go_to('next', 'start', '@block.outer') end
function M.next_return_start() return go_to('next', 'start', '@return.outer') end
function M.next_conditional_start() return go_to('next', 'start', '@conditional.outer') end
function M.next_function_start() return go_to('next', 'start', '@function.outer') end
function M.next_parameter_start() return go_to('next', 'start', '@parameter.inner') end
function M.previous_loop_start() return go_to('previous', 'start', '@loop.outer') end
function M.previous_class_start() return go_to('previous', 'start', '@class.outer') end
function M.previous_block_start() return go_to('previous', 'start', '@block.outer') end
function M.previous_return_start() return go_to('previous', 'start', '@return.outer') end
function M.previous_conditional_start() return go_to('previous', 'start', '@conditional.outer') end
function M.previous_function_start() return go_to('previous', 'start', '@function.outer') end
function M.previous_parameter_start() return go_to('previous', 'start', '@parameter.inner') end

function M.next_loop_end() return go_to('next', 'end', '@loop.outer') end
function M.next_class_end() return go_to('next', 'end', '@class.outer') end
function M.next_block_end() return go_to('next', 'end', '@block.outer') end
function M.next_return_end() return go_to('next', 'end', '@return.outer') end
function M.next_conditional_end() return go_to('next', 'end', '@conditional.outer') end
function M.next_function_end() return go_to('next', 'end', '@function.outer') end
function M.next_parameter_end() return go_to('next', 'end', '@parameter.inner') end
function M.previous_loop_end() return go_to('previous', 'end', '@loop.outer') end
function M.previous_class_end() return go_to('previous', 'end', '@class.outer') end
function M.previous_block_end() return go_to('previous', 'end', '@block.outer') end
function M.previous_return_end() return go_to('previous', 'end', '@return.outer') end
function M.previous_conditional_end() return go_to('previous', 'end', '@conditional.outer') end
function M.previous_function_end() return go_to('previous', 'end', '@function.outer') end
function M.previous_parameter_end() return go_to('previous', 'end', '@parameter.inner') end

function M.around_function() return select('@function.outer')() end
function M.around_class() return select('@class.outer')() end
function M.around_block() return select('@block.outer')() end
function M.around_conditional() return select('@conditional.outer')() end
function M.around_loop() return select('@loop.outer')() end
function M.around_return() return select('@return.outer')() end
function M.around_parameter() return select('@parameter.outer')() end
function M.inside_function() return select('@function.inner')() end
function M.inside_class() return select('@class.inner')() end
function M.inside_block() return select('@block.inner')() end
function M.inside_conditional() return select('@conditional.inner')() end
function M.inside_loop() return select('@loop.inner')() end
function M.inside_return() return select('@return.inner')() end
function M.inside_parameter() return select('@parameter.inner')() end

function M.swap_with_next_function() return swap('next', '@function.outer') end
function M.swap_with_next_class() return swap('next', '@class.outer') end
function M.swap_with_next_block() return swap('next', '@block.outer') end
function M.swap_with_next_conditional() return swap('next', '@conditional.outer') end
function M.swap_with_next_loop() return swap('next', '@loop.outer') end
function M.swap_with_next_return() return swap('next', '@return.outer') end
function M.swap_with_next_parameter() return swap('next', '@parameter.inner') end
function M.swap_with_previous_class() return swap('previous', '@class.outer') end
function M.swap_with_previous_function() return swap('previous', '@function.outer') end
function M.swap_with_previous_block() return swap('previous', '@block.outer') end
function M.swap_with_previous_conditional() return swap('previous', '@conditional.outer') end
function M.swap_with_previous_loop() return swap('previous', '@loop.outer') end
function M.swap_with_previous_return() return swap('previous', '@return.outer') end
function M.swap_with_previous_parameter() return swap('previous', '@parameter.inner') end

function M.repmove_comma() return require('repmove').comma() end
function M.repmove_semicolon() return require('repmove').semicolon() end
function M.repmove_builtin_f() return require('repmove').builtin_f() end
function M.repmove_builtin_F() return require('repmove').builtin_F() end
function M.repmove_builtin_t() return require('repmove').builtin_t() end
function M.repmove_builtin_T() return require('repmove').builtin_T() end
function M.repmove_next_misspelled() return ensure_repmove('[s', ']s')[2]() end
function M.repmove_next_function_start() return ensure_repmove(M.previous_function_start, M.next_function_start)[2]() end
function M.repmove_next_class_start() return ensure_repmove(M.previous_class_start, M.next_class_start)[2]() end
function M.repmove_next_block_start() return ensure_repmove(M.previous_block_start, M.next_block_start)[2]() end
function M.repmove_next_loop_start() return ensure_repmove(M.previous_loop_start, M.next_loop_start)[2]() end
function M.repmove_next_return_start() return ensure_repmove(M.previous_return_start, M.next_return_start)[2]() end
function M.repmove_next_parameter_start() return ensure_repmove(M.previous_parameter_start, M.next_parameter_start)[2]() end
function M.repmove_next_conditional_start() return ensure_repmove(M.previous_conditional_start, M.next_conditional_start)[2]() end
function M.repmove_next_function_end() return ensure_repmove(M.previous_function_end, M.next_function_end)[2]() end
function M.repmove_next_class_end() return ensure_repmove(M.previous_class_end, M.next_class_end)[2]() end
function M.repmove_next_block_end() return ensure_repmove(M.previous_block_end, M.next_block_end)[2]() end
function M.repmove_next_loop_end() return ensure_repmove(M.previous_loop_end, M.next_loop_end)[2]() end
function M.repmove_next_return_end() return ensure_repmove(M.previous_return_end, M.next_return_end)[2]() end
function M.repmove_next_parameter_end() return ensure_repmove(M.previous_parameter_end, M.next_parameter_end)[2]() end
function M.repmove_next_conditional_end() return ensure_repmove(M.previous_conditional_end, M.next_conditional_end)[2]() end
function M.repmove_previous_misspelled() return ensure_repmove('[s', ']s')[1]() end
function M.repmove_previous_function_start() return ensure_repmove(M.previous_function_start, M.next_function_start)[1]() end
function M.repmove_previous_class_start() return ensure_repmove(M.previous_class_start, M.next_class_start)[1]() end
function M.repmove_previous_block_start() return ensure_repmove(M.previous_block_start, M.next_block_start)[1]() end
function M.repmove_previous_loop_start() return ensure_repmove(M.previous_loop_start, M.next_loop_start)[1]() end
function M.repmove_previous_return_start() return ensure_repmove(M.previous_return_start, M.next_return_start)[1]() end
function M.repmove_previous_parameter_start() return ensure_repmove(M.previous_parameter_start, M.next_parameter_start)[1]() end
function M.repmove_previous_conditional_start() return ensure_repmove(M.previous_conditional_start, M.next_conditional_start)[1]() end
function M.repmove_previous_function_end() return ensure_repmove(M.previous_function_end, M.next_function_end)[1]() end
function M.repmove_previous_class_end() return ensure_repmove(M.previous_class_end, M.next_class_end)[1]() end
function M.repmove_previous_block_end() return ensure_repmove(M.previous_block_end, M.next_block_end)[1]() end
function M.repmove_previous_loop_end() return ensure_repmove(M.previous_loop_end, M.next_loop_end)[1]() end
function M.repmove_previous_return_end() return ensure_repmove(M.previous_return_end, M.next_return_end)[1]() end
function M.repmove_previous_parameter_end() return ensure_repmove(M.previous_parameter_end, M.next_parameter_end)[1]() end
function M.repmove_previous_conditional_end() return ensure_repmove(M.previous_conditional_end, M.next_conditional_end)[1]() end
-- stylua: ignore end

return M
