local M = {}

local util = require('lightboat.util')
--- @type table<string, boolean>
local plugin_loaded = {}
local function ensure_plugin(name)
  if not plugin_loaded[name] then
    require(name)
    plugin_loaded[name] = true
  end
end

-- HACK:
-- Those below do not support vim.v.count
local function next_todo() return require('todo-comments').jump_next() end
local function previous_todo() return require('todo-comments').jump_prev() end

local function previous_conflict()
  ensure_plugin('git-conflict')
  return '<plug>(git-conflict-prev-conflict)'
end
local function next_conflict()
  ensure_plugin('git-conflict')
  return '<plug>(git-conflict-next-conflict)'
end
local function next_git_hunk()
  require('gitsigns').nav_hunk('next')
  return true
end
local function previous_git_hunk()
  require('gitsigns').nav_hunk('prev')
  return true
end

local last_count = 1
local function hack(suffix, key)
  suffix = suffix or ''
  key = key or (suffix == '' and 's' or 'S')
  local op = vim.v.operator
  if op ~= 'g@' then last_count = vim.v.count1 end
  local res
  if op == 'y' then
    res = M['surround_normal' .. suffix]
  elseif op == 'd' then
    res = M['surround_delete' .. suffix]
  elseif op == 'c' then
    res = M['surround_change' .. suffix]
  elseif op == 'g@' and vim.o.operatorfunc:find('nvim%-surround') then
    -- HACK:
    -- We can not tell if now is in non line mode, which means "ySs" will behavior like "ySS"
    res = M['surround_normal_current' .. suffix]
  end
  if not res then return key end
  if op ~= 'g@' then
    util.key.feedkeys('<esc>', 'n')
    vim.schedule(function() util.key.feedkeys(tostring(vim.v.count1) .. res(), 'n') end)
  else
    util.key.feedkeys('<esc>' .. tostring(last_count) .. res(), 'n')
  end
  return true
end

--- @param key string
local function auto_pair(key)
  local core = require('ultimate-autopair.core')
  core.get_run(util.key.termcodes(key))
  return core.run_run(util.key.termcodes(key))
end

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
local function go_to(direction, position, query_string, query_group)
  require('nvim-treesitter-textobjects.move')['goto_' .. direction .. '_' .. position](query_string, query_group)
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
--- @param next string|function
--- @param comma? string|function
--- @param semicolon? string|function
--- @return table<function>
local function ensure_repmove(previous, next, comma, semicolon)
  if not repmove[previous] or not repmove[next] then
    repmove[previous], repmove[next] = require('repmove').make(previous, next, comma, semicolon)
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

-- stylua: ignore start
-- HACK:
-- This below can not cycle
local function next_loop_start() return go_to('next', 'start', '@loop.outer') end
local function next_class_start() return go_to('next', 'start', '@class.outer') end
local function next_block_start() return go_to('next', 'start', '@block.outer') end
local function next_return_start() return go_to('next', 'start', '@return.outer') end
local function next_conditional_start() return go_to('next', 'start', '@conditional.outer') end
local function next_function_start() return go_to('next', 'start', '@function.outer') end
local function next_parameter_start() return go_to('next', 'start', '@parameter.inner') end
local function previous_loop_start() return go_to('previous', 'start', '@loop.outer') end
local function previous_class_start() return go_to('previous', 'start', '@class.outer') end
local function previous_block_start() return go_to('previous', 'start', '@block.outer') end
local function previous_return_start() return go_to('previous', 'start', '@return.outer') end
local function previous_conditional_start() return go_to('previous', 'start', '@conditional.outer') end
local function previous_function_start() return go_to('previous', 'start', '@function.outer') end
local function previous_parameter_start() return go_to('previous', 'start', '@parameter.inner') end

local function next_loop_end() return go_to('next', 'end', '@loop.outer') end
local function next_class_end() return go_to('next', 'end', '@class.outer') end
local function next_block_end() return go_to('next', 'end', '@block.outer') end
local function next_return_end() return go_to('next', 'end', '@return.outer') end
local function next_conditional_end() return go_to('next', 'end', '@conditional.outer') end
local function next_function_end() return go_to('next', 'end', '@function.outer') end
local function next_parameter_end() return go_to('next', 'end', '@parameter.inner') end
local function previous_loop_end() return go_to('previous', 'end', '@loop.outer') end
local function previous_class_end() return go_to('previous', 'end', '@class.outer') end
local function previous_block_end() return go_to('previous', 'end', '@block.outer') end
local function previous_return_end() return go_to('previous', 'end', '@return.outer') end
local function previous_conditional_end() return go_to('previous', 'end', '@conditional.outer') end
local function previous_function_end() return go_to('previous', 'end', '@function.outer') end
local function previous_parameter_end() return go_to('previous', 'end', '@parameter.inner') end

-- HACK:
-- Those below do not support vim.v.count
local function next_section() require('vim.treesitter._headings').jump({ count = 1 }) return true end
local function previous_section() require('vim.treesitter._headings').jump({ count = -1 }) return true end

-- HACK:
-- Those below do not support vim.v.count
function M.around_function() return select('@function.outer') end
function M.around_class() return select('@class.outer') end
function M.around_block() return select('@block.outer') end
function M.around_conditional() return select('@conditional.outer') end
function M.around_loop() return select('@loop.outer') end
function M.around_return() return select('@return.outer') end
function M.around_parameter() return select('@parameter.outer') end
function M.inside_function() return select('@function.inner') end
function M.inside_class() return select('@class.inner') end
function M.inside_block() return select('@block.inner') end
function M.inside_conditional() return select('@conditional.inner') end
function M.inside_loop() return select('@loop.inner') end
function M.inside_return() return select('@return.inner') end
function M.inside_parameter() return select('@parameter.inner') end

-- HACK:
-- this below do not support vim.v.count
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

-- HACK:
-- Those below do not support vim.v.count
function M.comma() return require('repmove').comma() end
function M.semicolon() return require('repmove').semicolon() end
function M.f() return ensure_repmove('F', 'f', ',', ';')[2]() end
function M.F() return ensure_repmove('F', 'f', ',', ';')[1]() end
function M.t() return ensure_repmove('T', 't', ',', ';')[2]() end
function M.T() return ensure_repmove('T', 't', ',', ';')[1]() end
function M.next_misspelled() return ensure_repmove('[s', ']s')[2]() end
function M.previous_misspelled() return ensure_repmove('[s', ']s')[1]() end

function M.next_function_start() return ensure_repmove(previous_function_start, next_function_start)[2]() end
function M.next_class_start() return ensure_repmove(previous_class_start, next_class_start)[2]() end
function M.next_block_start() return ensure_repmove(previous_block_start, next_block_start)[2]() end
function M.next_loop_start() return ensure_repmove(previous_loop_start, next_loop_start)[2]() end
function M.next_return_start() return ensure_repmove(previous_return_start, next_return_start)[2]() end
function M.next_parameter_start() return ensure_repmove(previous_parameter_start, next_parameter_start)[2]() end
function M.next_conditional_start() return ensure_repmove(previous_conditional_start, next_conditional_start)[2]() end
function M.next_function_end() return ensure_repmove(previous_function_end, next_function_end)[2]() end
function M.next_class_end() return ensure_repmove(previous_class_end, next_class_end)[2]() end
function M.next_block_end() return ensure_repmove(previous_block_end, next_block_end)[2]() end
function M.next_loop_end() return ensure_repmove(previous_loop_end, next_loop_end)[2]() end
function M.next_return_end() return ensure_repmove(previous_return_end, next_return_end)[2]() end
function M.next_parameter_end() return ensure_repmove(previous_parameter_end, next_parameter_end)[2]() end
function M.next_conditional_end() return ensure_repmove(previous_conditional_end, next_conditional_end)[2]() end
function M.previous_function_start() return ensure_repmove(previous_function_start, next_function_start)[1]() end
function M.previous_class_start() return ensure_repmove(previous_class_start, next_class_start)[1]() end
function M.previous_block_start() return ensure_repmove(previous_block_start, next_block_start)[1]() end
function M.previous_loop_start() return ensure_repmove(previous_loop_start, next_loop_start)[1]() end
function M.previous_return_start() return ensure_repmove(previous_return_start, next_return_start)[1]() end
function M.previous_parameter_start() return ensure_repmove(previous_parameter_start, next_parameter_start)[1]() end
function M.previous_conditional_start() return ensure_repmove(previous_conditional_start, next_conditional_start)[1]() end
function M.previous_function_end() return ensure_repmove(previous_function_end, next_function_end)[1]() end
function M.previous_class_end() return ensure_repmove(previous_class_end, next_class_end)[1]() end
function M.previous_block_end() return ensure_repmove(previous_block_end, next_block_end)[1]() end
function M.previous_loop_end() return ensure_repmove(previous_loop_end, next_loop_end)[1]() end
function M.previous_return_end() return ensure_repmove(previous_return_end, next_return_end)[1]() end
function M.previous_parameter_end() return ensure_repmove(previous_parameter_end, next_parameter_end)[1]() end
function M.previous_conditional_end() return ensure_repmove(previous_conditional_end, next_conditional_end)[1]() end

function M.next_section() return ensure_repmove(previous_section, next_section)[2]() end
function M.previous_section() return ensure_repmove(previous_section, next_section)[1]() end

function M.select_file() update_selection(0, 0, vim.api.nvim_buf_line_count(0), 0, 'V') return true end

function M.next_completion_item() return require('blink.cmp').select_next() end
function M.previous_completion_item() return require('blink.cmp').select_prev() end
function M.accept_completion_item() return require('blink.cmp').accept() end
function M.cancel_completion() return require('blink.cmp').cancel() end
function M.show_completion() return require('blink.cmp').show() end
function M.hide_completion() return require('blink.cmp').hide() end
function M.snippet_forward() return require('blink.cmp').snippet_forward() end
function M.snippet_backward() return require('blink.cmp').snippet_backward() end
function M.show_signature() return require('blink.cmp').show_signature() end
function M.hide_signature() return require('blink.cmp').hide_signature() end
function M.scroll_documentation_up() return require('blink.cmp').scroll_documentation_up() end
function M.scroll_documentation_down() return require('blink.cmp').scroll_documentation_down() end
function M.scroll_signature_up() return require('blink.cmp').scroll_signature_up() end
function M.scroll_signature_down() return require('blink.cmp').scroll_signature_down() end

function M.async_format() return require('conform').format({ async = true }) end
function M.async_format_selection()
  return require('conform').format({ async = true }, function(err)
    if not err then util.feedkeys('<esc>', 'n') end
  end)
end

function M.next_todo() return ensure_repmove(previous_todo, next_todo)[2]() end
function M.previous_todo() return ensure_repmove(previous_todo, next_todo)[1]() end

function M.auto_pair_wrap(key) return function() return auto_pair(key) end end

function M.surround_normal() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-normal)' end
function M.surround_normal_current() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-normal-cur)' end
function M.surround_normal_line() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-normal-line)' end
function M.surround_normal_current_line() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-normal-cur-line)' end
function M.surround_insert() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-insert)' end
function M.surround_insert_line() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-insert-line)' end
function M.surround_delete() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-delete)' end
function M.surround_change() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-change)' end
function M.surround_change_line() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-change-line)' end
function M.surround_visual() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-visual)' end
function M.surround_visual_line() ensure_plugin('nvim-surround') return '<plug>(nvim-surround-visual-line)' end

function M.hack_wrap(suffix, key) return function() return hack(suffix, key) end end

function M.stage_hunk() require('gitsigns').stage_hunk() return true end
function M.undo_stage_hunk() require('gitsigns').undo_stage_hunk() return true end
function M.stage_buffer() require('gitsigns').stage_buffer() return true end
function M.unstage_buffer() require('gitsigns').reset_buffer_index() return true end
function M.stage_selection() require('gitsigns').stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) return true end
function M.reset_hunk() require('gitsigns').reset_hunk() return true end
function M.reset_buffer() require('gitsigns').reset_buffer() return true end
function M.reset_selection() require('gitsigns').reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) return true end
function M.preview_hunk() require('gitsigns').preview_hunk() return true end
function M.preview_hunk_inline() require('gitsigns').preview_hunk_inline() return true end
function M.blame_line() require('gitsigns').blame_line({ full = true }) return true end
function M.toggle_current_line_blame()
  util.toggle_notify('Current Line Blame', require('gitsigns').toggle_current_line_blame(), { title = 'Git Signs'})
  return true end
function M.toggle_word_diff()
  util.toggle_notify('Word Diff', require('gitsigns').toggle_word_diff(), { title = 'Git Signs' })
  return true end
function M.select_hunk() require('gitsigns').select_hunk() return true end
function M.previous_hunk() return ensure_repmove(previous_git_hunk, next_git_hunk)[1]() end
function M.next_hunk() return ensure_repmove(previous_git_hunk, next_git_hunk)[2]() end
function M.previous_conflict() return ensure_repmove(next_conflict, previous_conflict)[1]() end
function M.next_conflict() return ensure_repmove(next_conflict, previous_conflict)[2]() end

function M.comment() ensure_plugin('Comment') return '<plug>(comment_toggle_linewise)' end
function M.comment_line() ensure_plugin('Comment') return vim.v.count > 0 and '<plug>(comment_toggle_linewise_count)' or '<plug>(comment_toggle_linewise_current)' end
function M.comment_line_insert() -- TODO:
end
function M.comment_selection() ensure_plugin('Comment') return '<plug>(comment_toggle_linewise_visual)' end
function M.comment_block_style() ensure_plugin('Comment') return '<plug>(comment_toggle_blockwise)' end
function M.comment_line_block_style() ensure_plugin('Comment') return vim.v.count > 0 and '<plug>(comment_toggle_blockwise_count)' or '<plug>(comment_toggle_blockwise_current)' end
function M.comment_line_block_style_insert() -- TODO:
end
function M.comment_selection_block_style() ensure_plugin('Comment') return '<plug>(comment_toggle_blockwise_visual)' end
function M.comment_above() require('Comment.api').insert.linewise.above() return true end
function M.comment_below() require('Comment.api').insert.linewise.below() return true end
function M.comment_eol() require('Comment.api').insert.linewise.eol()return true end
function M.comment_above_block_style() require('Comment.api').insert.blockwise.above() return true end
function M.comment_below_block_style() require('Comment.api').insert.blockwise.below() return true end
function M.comment_eol_block_style() require('Comment.api').insert.blockwise.eol() return true end
-- stylua: ignore end

return M
