local util = require('lightboat.util')
local map = util.key.set
local del = util.key.del
local line_wise_key_wrap = require('lightboat.extra.line_wise').line_wise_key_wrap
local config = require('lightboat.config')
local c
local group

local function prepare_system_clipboard()
  local plus_reg_content = vim.fn.getreg('+'):gsub('\r', '')
  local anonymous_reg_content = vim.fn.getreg('"')
  vim.fn.setreg('+', plus_reg_content)
  vim.fn.setreg('"', plus_reg_content)
  vim.schedule(function() vim.fn.setreg('"', anonymous_reg_content) end)
  return plus_reg_content
end

local M = {}

local function sys_yank()
  if vim.tbl_contains({ 'v', 'V', '' }, vim.fn.mode('1')) then
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.schedule(function() vim.api.nvim_win_set_cursor(0, cursor) end)
  end
  return '"+y'
end

local function sys_paste()
  local res
  if vim.fn.mode('1') == 'i' then
    vim.cmd('set paste')
    vim.schedule(function() vim.cmd('set nopaste') end)
    res = '<c-g>u<c-r>+'
  else
    prepare_system_clipboard()
    res = '<plug>(YankyPutAfter)'
  end
  return res
end

local operation = {
  ['y'] = '<plug>(YankyYank)',
  ['p'] = '<plug>(YankyPutAfter)',
  ['gp'] = '<plug>(YankyGPutAfter)',
  ['gP'] = '<plug>(YankyGPutBefore)',
  ['P'] = '<plug>(YankyPutBefore)',
  ['Y'] = line_wise_key_wrap('y$'),
  ['<leader>Y'] = line_wise_key_wrap('"+y$'),
  ['<leader>y'] = sys_yank,
  ['<m-c>'] = sys_yank,
  ['<c-rightmouse>'] = sys_paste,
  ['<m-v>'] = function() return vim.fn.mode('1') == 'c' and '<c-r>+' or sys_paste() end,
  ['<leader>p'] = sys_paste,
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
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  spec.keys = {}
  if c and c.enabled then del('o', 'y') end
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.other.yanky', function()
  c = config.get().yanky
  if not c.enabled then return nil end
  map('o', 'y', function()
    if vim.v.operator == 'y' then
      return '<esc>' .. tostring(vim.v.count) .. line_wise_key_wrap('"' .. vim.v.register .. 'yy')()
    end
  end, { expr = true })
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  if c.restore_anonymous_reg then
    group = vim.api.nvim_create_augroup('LightBoatYanky', {})
    local before_anonymous_reg_content
    vim.api.nvim_create_autocmd('TextYankPost', {
      group = group,
      callback = function()
        if vim.v.event.regname ~= '' and vim.v.event.regname ~= '"' then
          vim.fn.setreg('"', before_anonymous_reg_content)
        end
      end,
    })
    vim.api.nvim_create_autocmd('ModeChanged', {
      group = group,
      callback = function() before_anonymous_reg_content = vim.fn.getreg('"') end,
      once = true,
    })
  end
  return spec
end, M.clear)

return M
