local util = require('lightboat.util')
local line_wise_key_wrap = require('lightboat.extra.line_wise').line_wise_key_wrap
local config = require('lightboat.config')
local c

local function prepare_system_clipboard()
  local plus_reg_content = vim.fn.getreg('+'):gsub('\r', '')
  local anonymous_reg_content = vim.fn.getreg('"')
  vim.fn.setreg('+', plus_reg_content)
  vim.fn.setreg('"', plus_reg_content)
  vim.schedule(function() vim.fn.setreg('"', anonymous_reg_content) end)
  return plus_reg_content
end

local M = {}

local operation = {
  ['y'] = '<plug>(YankyYank)',
  ['p'] = '<plug>(YankyPutAfter)',
  ['P'] = '<plug>(YankyPutBefore)',
  ['Y'] = line_wise_key_wrap('y$'),
  ['yy'] = line_wise_key_wrap('yy'),
  ['<leader>Y'] = line_wise_key_wrap('"+y$'),
  ['<leader>y'] = function()
    local before_anonymous_reg_content = vim.fn.getreg('"')
    vim.api.nvim_create_autocmd('TextYankPost', {
      pattern = '*',
      callback = function()
        local anonymous_reg_content = vim.fn.getreg('"')
        vim.fn.setreg('+', anonymous_reg_content)
        vim.fn.setreg('"', before_anonymous_reg_content)
      end,
      once = true,
    })
    return '<plug>(YankyYank)'
  end,
  ['<c-rightmouse>'] = function()
    local res
    if vim.fn.mode() == 'i' then
      local current_line = vim.api.nvim_get_current_line()
      if current_line:match('^%s*$') then
        vim.cmd('set paste')
        vim.schedule(function() vim.cmd('set nopaste') end)
        res = '<c-r>+'
      else
        local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
        local line_len = #current_line
        res = '<c-g>u<c-o><plug>(YankyPut' .. (line_len == cursor_col and 'After' or 'Before') .. 'Charwise)'
        local plus_reg_content = prepare_system_clipboard()
        if plus_reg_content:sub(-1) == '\n' then plus_reg_content = plus_reg_content:sub(1, -2) end
        local _, paste_line_num = string.gsub(plus_reg_content, '\n', '')
        local last_paste_line_len = #plus_reg_content:match('([^\n]*)$')
        cursor_row = cursor_row + paste_line_num
        if paste_line_num == 0 then
          cursor_col = cursor_col + last_paste_line_len
        else
          cursor_col = last_paste_line_len
        end
        vim.schedule(function() vim.api.nvim_win_set_cursor(0, { cursor_row, cursor_col }) end)
      end
    else
      res = '<plug>(YankyPutAfter)'
    end
    return res
  end,
  ['<m-v>'] = function() return vim.fn.mode() == 'c' and '<c-r>+' or '<c-rightmouse>' end,
  ['<leader>p'] = function()
    prepare_system_clipboard()
    return '<plug>(YankyPutAfter)'
  end,
  ['<leader>P'] = function()
    prepare_system_clipboard()
    return '<plug>(YankyPutBefore)'
  end,
  ['gy'] = function()
    if not Snacks then return end
    Snacks.picker.yanky({ focus = 'list' })
  end,
}

local spec = {
  'gbprod/yanky.nvim',
  opts = {
    picker = { highlight = { on_yank = true, on_put = true, timer = 50 } },
    system_clipboard = { sync_with_ring = true, clipboard_register = '+' },
  },
  keys = {},
}

function M.clear()
  spec.keys = {}
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.other.yanky', function()
  c = config.get().yanky
  if not c.enabled then return nil end
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
