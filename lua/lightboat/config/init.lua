local util = require('lightboat.util')

--- @class LightBoat.Opt
local default = {
  debug = false,
  autocmd = require('lightboat.config.autocmd'),
  keymap = require('lightboat.config.keymap'),
  buffer_line = require('lightboat.config.buffer_line'),
  comment = require('lightboat.config.comment'),
  conflict = require('lightboat.config.conflict'),
  dap = require('lightboat.config.dap'),
  extra = require('lightboat.config.extra'),
  -- flash = require('lightboat.config.flash'),
  img_clip = require('lightboat.config.img_clip'),
  interesting_words = require('lightboat.config.interesting_words'),
  neo_tree = require('lightboat.config.neo_tree'),
  noice = require('lightboat.config.noice'),
  non_ascii = require('lightboat.config.non_ascii'),
  overseer = require('lightboat.config.overseer'),
  pair = require('lightboat.config.pair'),
  resizer = require('lightboat.config.resizer'),
  sign = require('lightboat.config.sign'),
  snack = require('lightboat.config.snack'),
  todo = require('lightboat.config.todo'),
  ufo = require('lightboat.config.ufo'),
  which_key = require('lightboat.config.which_key'),
  yanky = require('lightboat.config.yanky'),
}

local M = {}

--- @type LightBoat.Opt
local user_opts = {}
function M.clear() vim.g.lightboat_opts = user_opts end

M.setup = util.setup_check_wrap('lightboat.config', function()
  --- @type LightBoat.Opt
  vim.g.lightboat_opts = vim.g.lightboat_opts or {}
  user_opts = vim.deepcopy(vim.g.lightboat_opts)
  vim.g.lightboat_opts = vim.tbl_deep_extend('force', default, vim.g.lightboat_opts)
end, M.clear)

--- @return LightBoat.Opt
function M.get() return vim.g.lightboat_opts end

return M
