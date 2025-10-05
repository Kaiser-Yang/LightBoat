local M = {}
local config = require('lightboat.config')
local c
local util = require('lightboat.util')
--- @param border 'top' | 'bottom' | 'left' | 'right'
function M.resize_wrap(border, reverse, abs_delta, first_left_or_right, first_top_or_bottom)
  first_left_or_right = first_left_or_right or 'right'
  first_top_or_bottom = first_top_or_bottom or 'top'
  local second_left_or_right = first_left_or_right == 'right' and 'left' or 'right'
  local second_top_or_bottom = first_top_or_bottom == 'bottom' and 'top' or 'bottom'
  abs_delta = abs_delta or 3
  local delta = (border == first_left_or_right or border == first_top_or_bottom) and abs_delta or -abs_delta
  local first = (border == first_left_or_right or border == second_left_or_right) and first_left_or_right
    or first_top_or_bottom
  local second = first == first_left_or_right and second_left_or_right or second_top_or_bottom
  return function()
    local resize = require('win.resizer').resize
    for _ = 1, vim.v.count1 do
      if reverse then
        local _ = resize(0, second, -delta, true)
          or resize(0, first, delta, true)
          or resize(0, second, -delta, false)
          or resize(0, first, delta, false)
      else
        local _ = resize(0, first, delta, true)
          or resize(0, second, -delta, true)
          or resize(0, first, delta, false)
          or resize(0, second, -delta, false)
      end
    end
  end
end

local operation = {
  ['<up>'] = M.resize_wrap('top'),
  ['<down>'] = M.resize_wrap('bottom'),
  ['<left>'] = M.resize_wrap('left'),
  ['<right>'] = M.resize_wrap('right'),
  ['<s-up>'] = M.resize_wrap('top', true),
  ['<s-down>'] = M.resize_wrap('bottom', true),
  ['<s-left>'] = M.resize_wrap('left', true),
  ['<s-right>'] = M.resize_wrap('right', true),
}

local spec = {
  'Kaiser-Yang/win-resizer.nvim',
  opts = { ignore_filetypes = { 'neo-tree', 'Avante', 'AvanteInput' } },
  keys = {},
}

function M.spec() return spec end

function M.clear()
  spec.kesy = {}
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.resizer', function()
  c = config.get().resizer
  if not c.enabled then return nil end
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
