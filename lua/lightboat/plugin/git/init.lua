local util = require('lightboat.util')
local name = 'lightboat.plugin.git'

local M = {
  conflict = require('lightboat.plugin.git.conflict'),
  sign = require('lightboat.plugin.git.sign'),
  octo = require('lightboat.plugin.git.octo'),
}

function M.clear() util.clear_plugins(M, name) end

M.setup = util.setup_check_wrap(name, function() return util.setup_plugins(M, name) end, M.clear)

return { M.setup() }
