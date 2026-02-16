local M = {}
local c = require('lightboat.condition')

local util = require('lightboat.util')
local function ensure_plugin(name)
  if not vim.g.plugin_loaded[name] then require(name) end
end

end

-- HACK:
-- This will break the dot repeat
local function toggle_comment_insert_mode()
  local commentstring = vim.bo.commentstring
  if not commentstring or commentstring:match('^%s*$') or commentstring:find('%%s') == nil then return end

  local indent, line = vim.api.nvim_get_current_line():match('^(%s*)(.*)$')
  -- split commentstring into left and right around "%s"
  local left, right = commentstring:match('^(.-)%%s(.-)$')
  left = left or ''
  right = right or ''

  -- cursor col BEFORE change (0-indexed)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local col = cursor[2]

  -- detect if the line (after indent) is already wrapped by left and right
  local has_left = (#left == 0) or (line:sub(1, #left) == left)
  local has_right = (#right == 0) or (line:sub(-#right) == right)

  local new_line
  local shift = 0 -- desired change in column relative to original col

  if has_left and has_right then
    -- remove the surrounding left/right (toggle off)
    local content_start = #left + 1
    local content_end = #line - #right
    if content_end < content_start then
      new_line = indent
    else
      new_line = indent .. line:sub(content_start, content_end)
    end
    shift = -#left
  else
    -- add left and right around the existing content (toggle on)
    new_line = indent .. left .. line .. right
    shift = #left
  end

  -- apply the new line (this may move the cursor automatically)
  vim.api.nvim_set_current_line(new_line)

  -- compute desired column after the change, clamped to the new line length and not before indent
  local new_content_len = #new_line - #indent
  if new_content_len < 0 then new_content_len = 0 end
  local min_col = #indent
  local max_col = #indent + math.max(0, new_content_len)
  local desired_col = col
  if col >= #indent then
    desired_col = col + shift
    if desired_col < min_col then desired_col = min_col end
    if desired_col > max_col then desired_col = max_col end
  end

  -- read actual column after set_current_line
  local actual_col = vim.api.nvim_win_get_cursor(0)[2]

  local delta = desired_col - actual_col
  return string.rep(delta > 0 and '<right>' or '<left>', math.abs(delta))
end

M.auto_indent = function()
  if vim.bo.indentexpr == '' and vim.o.indentexpr == '' then return false end
  return '<c-f>'
end

local last_count = 1
local function hack(suffix)
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
    -- HACK:
    -- We can not tell if now is in non line mode, which means "ySs" will behavior like "ySS"
    res = M['surround_normal_current' .. suffix]
  end
  if not res then return false end
  if op ~= 'g@' then
    util.key.feedkeys('<esc>' .. tostring(vim.v.count1) .. res() .. (is_S and '$' or ''), 'n')
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
M.markdown_code_block = '<c-g>u<bs>```<cr>```<cr><cr><++>' .. string.rep('<up>', 3)
function M.markdown_goto_placeholder()
  local pattern = '<++>'
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local cur_buf = vim.api.nvim_get_current_buf()
  local row_end = math.min(row + 100, vim.api.nvim_buf_line_count(cur_buf))
  local match = vim.fn.matchbufline(cur_buf, pattern, row, row_end)[1]
  if match then
    if match.lnum == row then
      return '<c-g>u<bs>'
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
  if util.buffer.big() then return false end
  require('nvim-treesitter-textobjects.move')['goto_' .. direction .. '_' .. position](query_string, query_group)
  -- HACK:
  -- We do not know if the operation is successful or not, so just return true
  return true
end

local function select(query_string, query_group)
  if util.buffer.big() then return false end
  require('nvim-treesitter-textobjects.select').select_textobject(query_string, query_group)
  -- HACK:
  -- We do not know if the operation is successful or not, so just return true
  return true
end

--- @param direction 'next'|'previous'
local function swap(direction, query_string)
  if util.buffer.big() then return false end
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
local function ensure_repmove(previous, next, comma, semicolon, rp)
  rp = rp or repmove
  if not rp[previous] or not rp[next] then
    rp[previous], rp[next] = require('repmove').make(previous, next, comma, semicolon)
  end
  return { rp[previous], rp[next] }
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
local function next_section_start() require('vim.treesitter._headings').jump({ count = 1 }) return true end
local function previous_section_start() require('vim.treesitter._headings').jump({ count = -1 }) return true end
-- TODO:
-- Find a better way to do this
local previous_section_end = previous_section_start
local next_section_end = next_section_start

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

function M.previous_section_start() return ensure_repmove(previous_section_start, next_section_start)[1]() end
function M.next_section_start() return ensure_repmove(previous_section_start, next_section_start)[2]() end
function M.previous_section_end() return ensure_repmove(previous_section_end, next_section_end)[1]() end
function M.next_section_end() return ensure_repmove(previous_section_end, next_section_end)[2]() end

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

local function close_pair_wrap(close, pattern)
  return function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local content_after_cursor = vim.api.nvim_get_current_line():sub(col + 1)
    local next_close = content_after_cursor:match(pattern)
    if not next_close then return close end
    vim.api.nvim_win_set_cursor(0, { row, col + #next_close })
  return ''
end
end
--- nil   --> quotations are not matched
--- false --> pairs are not matched or not in pairs
--- true  --> in pairs
local function in_pair()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local cnt = {
      ['()'] = 0,
      ['[]'] = 0,
      ['{}'] = 0,
    }
    local match = {
      ['"'] = true,
      ["'"] = true,
      ['`'] = true,
    }
    local pair_ok = true
    for i = 1, #line do
      local ch = line:sub(i, i)
      if ch == '(' then cnt['()'] = cnt['()'] + 1
      elseif ch == ')' then cnt['()'] = cnt['()'] - 1
      elseif ch == '[' then cnt['[]'] = cnt['[]'] + 1
      elseif ch == ']' then cnt['[]'] = cnt['[]'] - 1
      elseif ch == '{' then cnt['{}'] = cnt['{}'] + 1
      elseif ch == '}' then cnt['{}'] = cnt['{}'] - 1 end
      if match[ch] ~= nil and
        (ch ~= "'" or i == 1 or not line:sub(i - 1, i - 1):match('%a'))
        then match[ch] = not match[ch] end
      if cnt['()'] < 0 or cnt['[]'] < 0 or cnt['{}'] < 0 then
        pair_ok = false
      end
    end
    local quotation_ok = match['"'] and match["'"] and match['`']
    if not quotation_ok then return nil end
    if not pair_ok then return false end
    local char_before = col ~= 0 and line:sub(col, col) or (row > 1 and vim.api.nvim_buf_get_lines(0, row - 2, row - 1, true)[1]:sub(-1) or '')
    local char_after = col ~= #line and line:sub(col + 1, col + 1) or (row < vim.api.nvim_buf_line_count(0) and vim.api.nvim_buf_get_lines(0, row, row + 1, true)[1]:sub(1, 1) or '')
    local matched = ''
    local ok = function(a, b)
      if a and b then matched = a .. b end
      return a and b and
        ((a == '(' and b == ')')
        or (a == '[' and b == ']')
        or (a == '{' and b == '}')
        or (a == '"' and b == '"')
        or (a == "'" and b == "'")
        or (a == '`' and b == '`'))
    end
    if ok(char_before, char_after) then return true, matched end
    if char_before:match('%s') and char_after:match('%s') and col ~= 0 and col ~= #line then
      local non_space_before = line:sub(1, col):match('(%S)%s*$')
      local non_space_after = line:sub(col + 1):match('^%s*(%S)')
      return ok(non_space_before, non_space_after), matched
    end
    return false, matched
end
local double_quotation = { }
local triple_quotation = {
  ["`"] = { 'markdown' },
  ['"'] = { 'python' },
  ["'"] = { 'python' },
}
local function quotation_wrap(sym)
  return function()
    if in_pair() == nil then return sym end
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local sym_before = line:sub(1, col):match(sym .. '*$') or ''
    local sym_after = line:sub(col + 1):match('^' .. sym .. '*') or ''
    if #sym_before == 0 then
      if #sym_after == 1 then
        return '<right>'
      end
    elseif #sym_before == 1 then
      if #sym_after == 1 then
        if double_quotation[sym] and vim.tbl_contains(double_quotation[sym], vim.bo.filetype) then
          return sym .. sym .. '<left>'
        else
          return '<right>'
        end
      end
    elseif #sym_before == 2 then
      if #sym_after == 0 then
        if triple_quotation[sym] and vim.tbl_contains(triple_quotation[sym], vim.bo.filetype) then
          return sym .. sym .. sym .. sym .. string.rep('<left>', 3)
        end
      end
    end
    return sym .. sym .. '<left>'
  end
end
local hack_auot_pair_for_big = {
  ['('] = '<c-g>u()<left>',
  ['['] = '<c-g>u[]<left>',
  ['{'] = '<c-g>u{}<left>',
  [')'] = close_pair_wrap(')', '[%s%]%}]*%)'),
  [']'] = close_pair_wrap(']', '[%s%}%)]*%]'),
  ['}'] = close_pair_wrap('}', '[%s%]%)]*%}'),
  [' '] = function()
    local ok, s = in_pair()
    if ok and s:sub(1, 1) ~= s:sub(2, 2) then
      return '<c-g>U  <left>'
    end
    return ' '
  end,
  ['"'] = quotation_wrap('"'),
  ["'"] = quotation_wrap("'"),
  ['`'] = quotation_wrap('`'),
  [util.key.termcodes('<bs>')] = function()
    if in_pair() then
      return '<del><bs>'
    end
    return '<bs>'
  end,
  [util.key.termcodes('<cr>')] = function()
    if in_pair() then
      return '<c-g>u<cr><cr><up>' .. (vim.bo.indentexpr == '' and vim.o.indentexpr == '' and '<tab>' or '<c-f>')
    end
    return '<cr>'
  end
}
function M.auto_pair_wrap(key) return function()
  if util.buffer.big() then
    local termcodes = util.key.termcodes(key)
    if not hack_auot_pair_for_big[termcodes] or #vim.api.nvim_get_current_line() > (
      type(vim.b.big_file_average_every_line_length) == 'number' and vim.b.big_file_average_every_line_length or
      type(vim.g.big_file_average_every_line_length) == 'number' and vim.g.big_file_average_every_line_length or
      math.huge
    ) then
      util.key.feedkeys(key, 'n')
    elseif type(hack_auot_pair_for_big[termcodes]) == 'string' then
      util.key.feedkeys(hack_auot_pair_for_big[termcodes], 'n')
    else
      util.key.feedkeys(hack_auot_pair_for_big[termcodes](), 'n')
    end
    return true
  end
  return auto_pair(key)
end end

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

function M.hack_wrap(suffix) return function() return hack(suffix) end end

function M.comment() return require('vim._comment').operator() end
function M.comment_line() return require('vim._comment').operator() .. '_' end
function M.comment_line_insert() return toggle_comment_insert_mode() end
function M.comment_selection() return M.comment() end
-- stylua: ignore end
-- HACK:
-- This function can not be repeatable
function M.delete_to_eol_insert()
  local line = vim.api.nvim_get_current_line()
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  util.key.feedkeys('<c-g>u', 'nt')
  vim.api.nvim_set_current_line(line:sub(1, cursor_col))
  return true
end

function M.delete_to_eol_command()
  local line = vim.fn.getcmdline()
  local col = vim.fn.getcmdpos() - 1
  return string.rep('<del>', #line - col)
end

-- HACK:
-- Find a way to implement this in command line mode
M.delete_to_eow_insert = '<c-g>u<cmd>normal! de<cr>'

function M.toggle_treesitter_highlight()
  local buf = vim.api.nvim_get_current_buf()
  local status = vim.treesitter.highlighter.active[buf] == nil
  util.toggle_notify('Treesitter Highlight', status, { title = 'Treesitter' })
  if status then
    vim.treesitter.start(buf)
  else
    vim.treesitter.stop(buf)
  end
  return true
end

function M.toggle_inlay_hint()
  local status = vim.lsp.inlay_hint.is_enabled() == false
  util.toggle_notify('Inlay Hint', status, { title = 'LSP' })
  vim.lsp.inlay_hint.enable(status)
  return true
end

function M.toggle_spell()
  local status = vim.wo.spell == false
  util.toggle_notify('Spell', status, { title = 'Neovim' })
  vim.wo.spell = status
  return true
end

function M.toggle_expandtab()
  local status = vim.bo.expandtab == false
  util.toggle_notify('Expandtab', status, { title = 'Neovim' })
  vim.bo.expandtab = status
  return true
end

local urp = {}
function M.repmove_wrap(previous, next, idx, comma, semicolon)
  return function() return ensure_repmove(previous, next, comma, semicolon, urp)[idx]() end
end


M.system_put_command = '<c-r>+'
M.system_put_insert = '<cmd>set paste<cr><c-g>u<c-r><c-r>+<cmd>set nopaste<cr>'
M.system_put = '"+p'
M.system_put_before = '"+P'
M.system_yank = '"+y'
M.system_cut = '"+d'
M.split_above = '<cmd>set nosplitbelow|split<cr>'
M.split_below = '<cmd>set splitbelow|split<cr>'
M.split_left = '<cmd>set nosplitright|vsplit<cr>'
M.split_right = '<cmd>set splitright|vsplit<cr>'
M.split_tab = '<cmd>tab split<cr>'
M.cursor_to_above_window = '<c-w>k'
M.cursor_to_below_window = '<c-w>j'
M.cursor_to_left_window = '<c-w>h'
M.cursor_to_right_window = '<c-w>l'
M.nop = '<nop>'
-- HACK:
-- Those two may break the dot repeat
M.cursor_to_eol_insert = '<c-g>U<end>'
M.cursor_to_first_non_blank_insert = '<c-g>U<c-o>^'
local format = { '^:', '^/', '^%?', '^:%s*!', '^:%s*lua%s+', '^:%s*lua%s*=%s*', '^:%s*=%s*', '^:%s*he?l?p?%s+', '^=' }
function M.cursor_to_bol_command()
  local line = vim.fn.getcmdtype() .. vim.fn.getcmdline()
  local matched = nil
  for _, p in pairs(format) do
    local cur_matched = line:match(p)
    if not matched or cur_matched and #cur_matched > #matched then matched = cur_matched end
  end
  if matched then
    return '<home>' .. string.rep('<right>', #matched - 1)
  else
    return '<home>'
  end
end

local hacked_actions = {
  smart_select_all = function(buffer)
    local picker = require('telescope.actions.state').get_current_picker(buffer)
    local all_selected = #picker:get_multi_selection() == picker.manager:num_results()
    local actions = require('telescope.actions')
    if all_selected then
      actions.drop_all(buffer)
    else
      actions.select_all(buffer)
    end
  end,
  which_key = function(buffer)
    local actions = require('telescope.actions')
    actions.which_key(buffer, { keybind_width = 14 })
  end,
}
local hacked_pickers = {
  find_files = function(opts)
    opts = opts or {}
    if vim.fn.executable('rg') == 1 and not opts.find_command then
      opts.find_command = { 'rg', '--files', '--color', 'never', '--glob', '!.git/*' }
      if util.in_config_dir() then table.insert(opts.find_command, '--hidden') end
    end
    require('telescope.builtin').find_files(opts)
  end,
  live_grep = function(opts)
    opts = opts or {}
    if not opts.additional_args and util.in_config_dir() then opts.additional_args = { '--hidden' } end
    require('telescope.builtin').live_grep(opts)
  end,
  grep_string = function(opts)
    opts = opts or {}
    if not opts.additional_args and util.in_config_dir() then opts.additional_args = { '--hidden' } end
    require('telescope.builtin').grep_string(opts)
  end,
  ['todo-comments'] = {
    todo = function(opts)
      opts = opts or {}
      if not opts.additional_args and util.in_config_dir() then opts.additional_args = { '--hidden' } end
      require('telescope').extensions['todo-comments'].todo(opts)
    end,
  },
}
function M.picker_wrap(name, opts)
  return function()
    if type(name) == 'string' then
      if hacked_pickers[name] then
        hacked_pickers[name](opts)
      else
        require('telescope.builtin')[name](opts)
      end
    else
      if hacked_pickers[name[1]] and hacked_pickers[name[1]][name[2]] then
        hacked_pickers[name[1]][name[2]](opts)
      else
        require('telescope').extensions[name[1]][name[2]](opts)
      end
    end
    return true
  end
end

function M.picker_action_wrap(...)
  local args = { ... }
  return function()
    local actions = require('telescope.actions')
    for _, name in pairs(args) do
      if hacked_actions[name] then
        hacked_actions[name](vim.api.nvim_get_current_buf())
      else
        actions[name](vim.api.nvim_get_current_buf())
      end
    end
    vim.api.nvim_exec_autocmds('User', { pattern = 'TelescopeKeymap' })
    return true
  end
end

return M
