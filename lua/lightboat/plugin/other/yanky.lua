local util = require('lightboat.util')
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
  ['y'] = function()
    if vim.fn.mode('1') == 'no' then
      if vim.v.operator == 'y' then
        return '<esc>' .. tostring(vim.v.count) .. line_wise_key_wrap('"' .. vim.v.register .. 'yy', c.keys['y'].opts)()
      end
    else
      return '<plug>(YankyYank)'
    end
  end,
  ['p'] = '<plug>(YankyPutAfter)',
  ['gp'] = '<plug>(YankyGPutAfter)',
  ['gP'] = '<plug>(YankyGPutBefore)',
  ['P'] = '<plug>(YankyPutBefore)',
  ['Y'] = function() return line_wise_key_wrap('y$', c.keys['Y'].opts)() end,
  ['<m-c>'] = function()
    if vim.fn.mode('1') == 'no' then
      if vim.v.operator == 'y' and vim.v.register == '+' then
        return '<esc>' .. tostring(vim.v.count) .. line_wise_key_wrap('"+yy', c.keys['<m-c>'].opts)()
      end
    else
      return '"+y'
    end
  end,
  ['<m-C>'] = function() return line_wise_key_wrap('"+y$', c.keys['<m-C>'].opts)() end,
  ['<c-rightmouse>'] = sys_paste,
  ['<m-v>'] = function()
    local mode = vim.fn.mode('1')
    if mode == 'no' then
      if vim.v.operator ~= 'y' then return end
      if vim.v.register == '+' then
        vim.fn.setreg('+', vim.fn.getreg('"'), vim.fn.getregtype('"'))
        vim.schedule(function() vim.notify('Restored + register from anonymous register', vim.log.levels.INFO) end)
        return '<esc>'
      elseif vim.v.register == '' or vim.v.register == '"' then
        vim.fn.setreg('"', vim.fn.getreg('+'), vim.fn.getregtype('+'))
        vim.schedule(function() vim.notify('Restored anonymous register from + register', vim.log.levels.INFO) end)
        return '<esc>'
      end
    elseif mode == 'c' then
      return '<c-r>+'
    else
      return sys_paste()
    end
  end,
  ['<m-V>'] = function()
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
    -- PERF:
    -- Paste or copy large text will be slow
    -- https://github.com/gbprod/yanky.nvim/issues/230
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
  spec.enabled = c.enabled
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  if c.restore_anonymous_reg then
    group = vim.api.nvim_create_augroup('LightBoatYanky', {})
    -- PERF:
    -- When the reg has a large content, this will use a lot of memory
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
