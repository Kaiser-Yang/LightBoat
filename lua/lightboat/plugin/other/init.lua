local util = require('lightboat.util')
local name = 'lightboat.plugin.other'

local M = {
  flash = require('lightboat.plugin.other.flash'),
  guess_indent = require('lightboat.plugin.other.guess_indent'),
  neo_tree = require('lightboat.plugin.other.neo_tree'),
  non_ascii = require('lightboat.plugin.other.non_ascii'),
  resizer = require('lightboat.plugin.other.resizer'),
  save = require('lightboat.plugin.other.save'),
  session = require('lightboat.plugin.other.session'),
  treesitter = require('lightboat.plugin.other.treesitter'),
  which_key = require('lightboat.plugin.other.which_key'),
  snack = require('lightboat.plugin.other.snack'),
  yanky = require('lightboat.plugin.other.yanky'),
}

function M.clear() util.clear_plugins(M, name) end

M.setup = util.setup_check_wrap(name, function() return util.setup_plugins(M, name) end, M.clear)

return { M.setup() }
