local util = require('lightboat.util')
local M = {}

local spec = {
  'mzlogin/vim-markdown-toc',
  ft = { 'markdown' },
}

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.other.markdown', function() return spec end, M.clear)

return M
