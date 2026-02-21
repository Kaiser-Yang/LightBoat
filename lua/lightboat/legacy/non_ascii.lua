local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local rep_move = require('lightboat.extra.rep_move')
local prev_word, next_word = rep_move.make(
  function() require('non-ascii').b() end,
  function() require('non-ascii').w() end
)
local prev_end_word, next_end_word = rep_move.make(
  function() require('non-ascii').ge() end,
  function() require('non-ascii').e() end
)

local operation = {
  ['b'] = function()
    if vim.fn.mode('1'):find('o') then
      require('non-ascii').b()
    else
      prev_word()
    end
  end,
  ['w'] = function()
    if vim.fn.mode('1'):find('o') then
      require('non-ascii').e()
    else
      next_word()
    end
  end,
  ['ge'] = function()
    if vim.fn.mode('1'):find('o') then
      require('non-ascii').ge()
    else
      prev_end_word()
    end
  end,
  ['e'] = function()
    if vim.fn.mode('1'):find('o') then
      require('non-ascii').e()
    else
      next_end_word()
    end
  end,
  ['iw'] = function() require('non-ascii').iw() end,
  ['aw'] = function() require('non-ascii').aw() end,
}

local M = {}

local spec = {
  'Kaiser-Yang/non-ascii.nvim',
  opts = { word = { word_files = { util.get_light_boat_root() .. '/dict/zh_dict.txt' } } },
  keys = {},
}

function M.spec() return spec end

function M.clear()
  c = nil
  spec.keys = {}
end

M.setup = util.setup_check_wrap('lightboat.plugin.other.non_ascii', function()
  c = config.get().non_ascii
  if not c.enabled then return end
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
