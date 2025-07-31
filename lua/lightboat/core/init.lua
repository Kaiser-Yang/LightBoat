local util = require('lightboat.util')
local log = util.log

--- @param name 'option' | 'keymap' | 'autocmd'
local function load(name)
  log.debug('Loading core module: ' .. name)
  require('lightboat.core.' .. name)
  require('core.' .. name)
end

local M = {}

function M.setup()
  load('option')
  load('autocmd')
  load('keymap')
end

return M
