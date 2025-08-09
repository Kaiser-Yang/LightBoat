local util = require('lightboat.util')
local name = 'lightboat.plugin.markdown'

local M = {
  img_clip = require('lightboat.plugin.markdown.img_clip'),
  renderer = require('lightboat.plugin.markdown.renderer'),
  toc = require('lightboat.plugin.markdown.toc'),
}

function M.clear() util.clear_plugins(M, name) end

M.setup = util.setup_check_wrap(name, function() return util.setup_plugins(M, name) end, M.clear)

return { M.setup() }
