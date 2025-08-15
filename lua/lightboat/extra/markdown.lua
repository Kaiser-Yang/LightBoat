local util = require('lightboat.util')
local config = require('lightboat.config')
local group
local c
local M = {}
local item_regex = {
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
  ['<localleader>a'] = '<c-g>u[](<++>)<++><esc>F[a',
  ['<localleader>b'] = '<c-g>u****<++><esc>F*hi',
  ['<localleader>c'] = '<c-g>u```<cr>```<cr><++><esc>2kA',
  ['<localleader>t'] = '<c-g>u``<++><esc>F`i',
  ['<localleader>m'] = '<c-g>u$$  $$<++><esc>F i',
  ['<localleader>d'] = '<c-g>u~~~~<++><esc>F~hi',
  ['<localleader>i'] = '<c-g>u**<++><esc>F*i',
  ['<localleader>M'] = '<c-g>u$$<cr><cr>$$<cr><++><esc>2kA',
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
