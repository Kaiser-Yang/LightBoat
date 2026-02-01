local util = require('lightboat.util')
local name = 'lightboat.plugin.ai'

local M = {
  -- avante = require('lightboat.plugin.ai.avante'),
  -- copilot = require('lightboat.plugin.ai.copilot'),
}

function M.clear() util.clear_plugins(M, name) end

M.setup = util.setup_check_wrap(name, function() return util.setup_plugins(M, name) end, M.clear)

return { M.setup() }
