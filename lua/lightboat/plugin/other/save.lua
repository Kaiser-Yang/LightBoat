local util = require('lightboat.util')
local spec = {
  'Pocco81/auto-save.nvim',
  event = 'VeryLazy',
  opts = { execution_message = { message = '' } },
}
local M = {}

function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.save', function() return spec end, M.clear)

return M
