local util = require('lightboat.util')
local log = util.log

--- @param name 'option' | 'keymap' | 'autocmd'
local function load(name)
  log.info('Loading core module: ' .. name)
  require('core.' .. name)
end

local M = {}

function M.setup()
  load('option')
  load('autocmd')
end

return M
