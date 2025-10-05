local util = require('lightboat.util')
local name = 'lightboat.plugin.code'

local M = {
  blink_cmp = require('lightboat.plugin.code.blink_cmp'),
  color = require('lightboat.plugin.code.color'),
  comment = require('lightboat.plugin.code.comment'),
  conform = require('lightboat.plugin.code.conform'),
  dap = require('lightboat.plugin.code.dap'),
  interesting_words = require('lightboat.plugin.code.interesting_words'),
  lsp = require('lightboat.plugin.code.lsp'),
  mason = require('lightboat.plugin.code.mason'),
  nvim_jdtls = require('lightboat.plugin.code.nvim_jdtls'),
  pair = require('lightboat.plugin.code.pair'),
  overseer = require('lightboat.plugin.code.overseer'),
  todo = require('lightboat.plugin.code.todo'),
}

function M.clear() util.clear_plugins(M, name) end

M.setup = util.setup_check_wrap(name, function() return util.setup_plugins(M, name) end, M.clear)

return { M.setup() }
