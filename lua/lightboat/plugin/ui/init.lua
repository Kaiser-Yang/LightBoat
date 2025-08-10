local util = require('lightboat.util')
local name = 'lightboat.plugin.ui'
local M = {
  buffer_line = require('lightboat.plugin.ui.buffer_line'),
  catppuccin = require('lightboat.plugin.ui.catppuccin'),
  lualine = require('lightboat.plugin.ui.lualine'),
  noice = require('lightboat.plugin.ui.noice'),
  statuscol = require('lightboat.plugin.ui.statuscol'),
  ufo = require('lightboat.plugin.ui.ufo'),
}

function M.clear() util.clear_plugins(M, name) end

M.setup = util.setup_check_wrap(name, function() return util.setup_plugins(M, name) end, M.clear)

return { M.setup() }
