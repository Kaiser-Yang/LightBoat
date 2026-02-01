local util = require('lightboat.util')
local h = require('lightboat.handler')

--- @class LightBoat.Opt
local default = {
  debug = false,
  autocmd = require('lightboat.config.autocmd'),
  keymap = require('lightboat.config.keymap'),
  blink_cmp = require('lightboat.config.blink_cmp'),
  buffer_line = require('lightboat.config.buffer_line'),
  comment = require('lightboat.config.comment'),
  conflict = require('lightboat.config.conflict'),
  conform = require('lightboat.config.conform'),
  dap = require('lightboat.config.dap'),
  extra = require('lightboat.config.extra'),
  flash = require('lightboat.config.flash'),
  img_clip = require('lightboat.config.img_clip'),
  interesting_words = require('lightboat.config.interesting_words'),
  lsp = require('lightboat.config.lsp'),
  mason = require('lightboat.config.mason'),
  neo_tree = require('lightboat.config.neo_tree'),
  noice = require('lightboat.config.noice'),
  non_ascii = require('lightboat.config.non_ascii'),
  overseer = require('lightboat.config.overseer'),
  pair = require('lightboat.config.pair'),
  resizer = require('lightboat.config.resizer'),
  sign = require('lightboat.config.sign'),
  snack = require('lightboat.config.snack'),
  todo = require('lightboat.config.todo'),
  treesitter = require('lightboat.config.treesitter'),
  ufo = require('lightboat.config.ufo'),
  which_key = require('lightboat.config.which_key'),
  yanky = require('lightboat.config.yanky'),
  --- @type LightBoat.GlobalKeySpec
  global_key = {
    ['1'] = {
      key = '1',
      mode = 'i',
      expr = true,
      handler = { title_1 = { priority = 0, handler = h.title(1, 'markdown') } },
    },
    ['2'] = {
      key = '2',
      mode = 'i',
      expr = true,
      handler = { title_2 = { priority = 0, handler = h.title(2, 'markdown') } },
    },
    ['3'] = {
      key = '3',
      mode = 'i',
      expr = true,
      handler = { title_3 = { priority = 0, handler = h.title(3, 'markdown') } },
    },
    ['4'] = {
      key = '4',
      mode = 'i',
      expr = true,
      handler = { title_4 = { priority = 0, handler = h.title(4, 'markdown') } },
    },
    ['s'] = {
      key = 's',
      mode = 'i',
      expr = true,
      handler = { separate_line = { priority = 0, handler = h.separate_line('markdown') } },
    },
  },
  buffer_key = {}
}

local M = {}

--- @type LightBoat.Opt
local user_opts = {}
function M.clear() vim.g.lightboat_opts = user_opts end

M.setup = util.setup_check_wrap('lightboat.config', function()
  --- @type LightBoat.Opt
  vim.g.lightboat_opts = vim.g.lightboat_opts or {}
  user_opts = vim.deepcopy(vim.g.lightboat_opts)
  if vim.g.lightboat_opts.global_key then
    vim.g.lightboat_opts.global_key = util.key.normalise_key(vim.g.lightboat_opts.global_key)
  end
  if vim.g.lightboat_opts.buffer_key then
    vim.g.lightboat_opts.buffer_key = util.key.normalise_key(vim.g.lightboat_opts.buffer_key)
  end
  default.global_key = util.key.normalise_key(default.global_key)
  default.buffer_key = util.key.normalise_key(default.buffer_key)
  vim.g.lightboat_opts = vim.tbl_deep_extend('force', default, vim.g.lightboat_opts)
  util.key.setup_buffer_key(vim.g.lightboat_opts.buffer_key)
  util.key.setup_global_key(vim.g.lightboat_opts.global_key)
end, M.clear)

--- @return LightBoat.Opt
function M.get() return vim.g.lightboat_opts end

return M
