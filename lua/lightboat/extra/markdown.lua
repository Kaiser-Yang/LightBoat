-- Some markdown support for markdown files
-- Author: KaiserYang

local util = require('lightboat.util')
local config = require('lightboat.config')
local group
local c
local M = {}
local item_regex = {
  list = '^ *([*-] )',
  number_list = '^ *(%d+%. )',
  reference = '^ *(> )',
  todo_list = {
    both = '^%s*([*-] %[[ x-]%] )',
    checked = '^%s*([*-] %[[x-]%] )',
    unchecked = '^%s*([*-] %[[ ]%] )',
  },
}
local function toggle_check_box_once(line_number)
  local item = nil
  local context = nil
  while true do
    if line_number <= 0 then break end
    context = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, true)[1]
    item = context:match(item_regex.todo_list.both)
    if item then
      local new_line = context:match('^%s*')
        .. string.gsub(
          context,
          item_regex.todo_list.both,
          item:match(item_regex.todo_list.checked) and '- [ ] ' or '- [x] '
        )
      vim.api.nvim_buf_set_lines(0, line_number - 1, line_number, true, { new_line })
      return line_number - 1
    end
    line_number = line_number - 1
  end
  return -1
end

local function toggle_check_box(start_line, end_line)
  start_line = start_line or vim.api.nvim_win_get_cursor(0)[1]
  end_line = end_line or start_line
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  while start_line <= end_line do
    end_line = toggle_check_box_once(end_line)
  end
end

vim.g.auto_pairs_cr = vim.g.auto_pairs_cr or '<cr>'
vim.g.auto_pairs_bs = vim.g.auto_pairs_bs or '<bs>'

--- @param line string
local function match_item(line, must_end)
  local longest_match = nil
  for _, regex_or_list in pairs(item_regex) do
    local regex_list = util.ensure_list(regex_or_list)
    for _, regex in pairs(regex_list) do
      local item = line:match(regex .. (must_end and '$' or ''))
      if not longest_match or (item and #item > #longest_match) then longest_match = item end
    end
  end
  return longest_match
end

--- Feed a list item by context
--- @param opts {cursor_line: number|nil}|nil
--- when cursor_line is nil, it will use the current cursor line number
--- @return boolean whether the list item is fed
local function feed_list_item_by_context(opts)
  local cursor_line = opts and opts.cursor_line or vim.api.nvim_win_get_cursor(0)[1]
  local item = nil
  local last_indent_pos = nil
  local context = nil
  while true do
    cursor_line = cursor_line - 1
    if cursor_line <= 0 then return false end
    context = vim.api.nvim_buf_get_lines(0, cursor_line - 1, cursor_line, true)[1]
    item = match_item(context)
    if item then
      item = string.gsub(item, 'x', ' ')
      util.key.feedkeys(item, 'n')
      return true
    elseif context:match('^ *$') then
      break
    end
    local match_result = context:match('^ *')
    if match_result == nil and last_indent_pos ~= nil and last_indent_pos ~= 0 then
      return false
    elseif match_result ~= nil and last_indent_pos ~= nil and last_indent_pos ~= #match_result then
      return false
    else
      last_indent_pos = match_result and #match_result or 0
    end
  end
  return false
end

local function finish_a_list()
  for _ = 1, vim.api.nvim_win_get_cursor(0)[2] do
    util.key.feedkeys('<bs>', 'n')
  end
  util.key.feedkeys('<c-g>u<cr>', 'n')
end

local function delete_a_list_item(item)
  for _ = 1, #item do
    util.key.feedkeys('<bs>', 'n')
  end
end

local function demote_a_list_item(item)
  delete_a_list_item(item)
  util.key.feedkeys('<tab>' .. item, 'n')
end

local function promote_a_list_item(item)
  delete_a_list_item(item)
  util.key.feedkeys('<bs>' .. item, 'n')
end

local function continue_a_list_item_next_line() util.key.feedkeys('<c-g>u<cr>', 'n') end

local function add_a_list_item_next_line(item)
  continue_a_list_item_next_line()
  util.key.feedkeys(item, 'n')
end

--- @type string?
local last_key_in_insert = nil

--- @return boolean
local function last_key_match_local_leader()
  return last_key_in_insert ~= nil
    and vim.api.nvim_replace_termcodes(last_key_in_insert, true, true, true)
      == vim.api.nvim_replace_termcodes(vim.g.maplocalleader, true, true, true)
end

--- @param origin string
--- @param new string
local function local_leader_check_wrap(origin, new)
  return function()
    if last_key_match_local_leader() then
      last_key_in_insert = nil
      return new
    else
      return origin
    end
  end
end
-- TODO: Those below not working in vscode-nvim
local operation = {
  ['f'] = function()
    if not last_key_match_local_leader() then return 'f' end
    local pattern = '<++>'
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local cur_buf = vim.api.nvim_get_current_buf()
    local row_end = math.min(row + c.markdown.max_search_lines - 1, vim.api.nvim_buf_line_count(cur_buf))
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
  end,
  ['1'] = local_leader_check_wrap('1', '<c-g>u<bs># '),
  ['2'] = local_leader_check_wrap('2', '<c-g>u<bs>## '),
  ['3'] = local_leader_check_wrap('3', '<c-g>u<bs>### '),
  ['4'] = local_leader_check_wrap('4', '<c-g>u<bs>#### '),
  ['a'] = local_leader_check_wrap('a', '<c-g>u<bs>[](<++>)<++>' .. string.rep('<c-g>U<left>', 11)),
  ['b'] = local_leader_check_wrap('b', '<c-g>u<bs>****<++>' .. string.rep('<c-g>U<left>', 6)),
  ['c'] = local_leader_check_wrap(
    'c',
    '<c-g>u<bs>```<cr>```<cr><cr><++>' .. string.rep('<up>', 3) .. string.rep('<right>', 3)
  ),
  ['d'] = local_leader_check_wrap('d', '<c-g>u<bs>~~~~<++>' .. string.rep('<c-g>U<left>', 6)),
  ['i'] = local_leader_check_wrap('i', '<c-g>u<bs>**<++>' .. string.rep('<c-g>U<left>', 5)),
  ['m'] = local_leader_check_wrap('m', '<c-g>u<bs>$$  $$<++>' .. string.rep('<c-g>U<left>', 7)),
  ['M'] = local_leader_check_wrap(
    'M',
    '<c-g>u<bs>$$<cr><cr>$$<cr><cr><++>' .. string.rep('<up>', 3) .. string.rep('<right>', 2)
  ),
  ['s'] = local_leader_check_wrap('s', '<c-g>u<bs>---<cr><cr>'),
  ['t'] = local_leader_check_wrap('t', '<c-g>u<bs>``<++>' .. string.rep('<c-g>U<left>', 5)),
  ['T'] = local_leader_check_wrap('T', '<c-g>u<bs>- [ ] '),
  ['o'] = 'A<cr>',
  ['<cr>'] = function()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local cursor_row, cursor_column = cursor_pos[1], cursor_pos[2]
    local content_before_cursor = vim.api.nvim_get_current_line():sub(1, cursor_column)
    local item = match_item(content_before_cursor, true)
    if item then
      if content_before_cursor:sub(1, 1) ~= ' ' then
        finish_a_list()
      else
        promote_a_list_item(item)
      end
    else
      item = match_item(content_before_cursor)
      if item then
        local next_line = ''
        if cursor_row < vim.api.nvim_buf_line_count(0) then
          next_line = vim.api.nvim_buf_get_lines(0, cursor_row, cursor_row + 1, true)[1]
        end
        if
          #content_before_cursor == #vim.api.nvim_get_current_line()
          and (match_item(next_line) or next_line:match('^ *$'))
        then
          item = string.gsub(item, 'x', ' ')
          -- vim.notify('111')
          add_a_list_item_next_line(item)
        else
          continue_a_list_item_next_line()
        end
      elseif content_before_cursor:match('^ *$') and feed_list_item_by_context() then
        -- pass
      else
        util.key.feedkeys('<c-g>u' .. vim.g.auto_pairs_cr, 'n')
      end
    end
  end,
  ['<bs>'] = function()
    local cursor_coloumn = vim.api.nvim_win_get_cursor(0)[2]
    local content_before_cursor = vim.api.nvim_get_current_line():sub(1, cursor_coloumn)
    local item = match_item(content_before_cursor, true)
    if item then
      delete_a_list_item(item)
    elseif content_before_cursor:match('^ +$') then
      util.key.feedkeys('<bs>', 'n')
      feed_list_item_by_context()
    else
      -- normal <bs>
      util.key.feedkeys(vim.g.auto_pairs_bs, 'n')
    end
  end,
  ['<tab>'] = function()
    local cursor_coloumn = vim.api.nvim_win_get_cursor(0)[2]
    local content_before_cursor = vim.api.nvim_get_current_line():sub(1, cursor_coloumn)
    local item = match_item(content_before_cursor, true)
    if item then
      demote_a_list_item(item)
    elseif content_before_cursor:match('^ *$') and feed_list_item_by_context() then
      -- pass
    else
      -- normal <tab>
      util.key.feedkeys('<tab>', 'n')
    end
  end,
  ['gx'] = function()
    toggle_check_box(vim.fn.line('v'), vim.fn.line('.'))
    if vim.fn.mode('1') ~= 'n' then util.key.feedkeys('<esc>', 'n') end
  end,
}

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_name(group)
    group = nil
  end
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.extra.markdown', function()
  c = config.get().extra
  if not c.markdown.enabled then return end

  group = vim.api.nvim_create_augroup('LightBoatExtraMarkdown', {})
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = c.markdown_fts,
    callback = function()
      if c.markdown.enable_spell_check then vim.cmd.setlocal('spell') end
      util.key.set_keys(operation, c.markdown.keys)
    end,
  })
  vim.api.nvim_create_autocmd('InsertEnter', {
    group = group,
    callback = function() last_key_in_insert = nil end,
  })
  vim.api.nvim_create_autocmd('InsertCharPre', {
    group = group,
    callback = function() last_key_in_insert = vim.v.char end,
  })
end, M.clear)

return M
