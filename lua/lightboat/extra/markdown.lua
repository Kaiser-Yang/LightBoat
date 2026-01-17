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
  for _, regex_or_list in pairs(item_regex) do
    local regex_list = util.ensure_list(regex_or_list)
    for _, regex in pairs(regex_list) do
      local item = line:match(regex .. (must_end and '$' or ''))
      if item then return item end
    end
  end
  return nil
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

local operation = {
  ['<localleader>f'] = function()
    local pattern = '<++>'
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local cur_buf = vim.api.nvim_get_current_buf()
    local row_end = math.max(row + c.markdown.max_search_lines - 1, vim.api.nvim_buf_line_count(cur_buf))
    local match = vim.fn.matchbufline(cur_buf, pattern, row, row_end)[1]
    if match then
      vim.api.nvim_win_set_cursor(0, { match.lnum, match.byteidx })
      util.key.feedkeys('<c-g>u' .. string.rep('<del>', #pattern), 'n')
    end
  end,
  ['<localleader>1'] = '<c-g>u# ',
  ['<localleader>2'] = '<c-g>u## ',
  ['<localleader>3'] = '<c-g>u### ',
  ['<localleader>4'] = '<c-g>u#### ',
  ['<localleader>a'] = '<c-g>u[](<++>)<++>' .. string.rep('<left>', 11),
  ['<localleader>b'] = '<c-g>u****<++>' .. string.rep('<left>', 6),
  ['<localleader>c'] = '<c-g>u```<cr>```<cr><++>' .. string.rep('<up>', 2) .. string.rep('<right>', 3),
  ['<localleader>d'] = '<c-g>u~~~~<++>' .. string.rep('<left>', 6),
  ['<localleader>i'] = '<c-g>u**<++>' .. string.rep('<left>', 5),
  ['<localleader>s'] = '<c-g>u---<cr><cr>',
  ['<localleader>t'] = '<c-g>u``<++>' .. string.rep('<left>', 5),
  ['<localleader>m'] = '<c-g>u$$  $$ <++>' .. string.rep('<left>', 8),
  ['<localleader>M'] = '<c-g>u$$<cr><cr>$$<cr><++>' .. string.rep('<up>', 2) .. string.rep('<right>', 2),
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
end, M.clear)

return M
