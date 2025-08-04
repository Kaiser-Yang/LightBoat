local util = require('lightboat.util')
local M = {}

function M.clear()
  require('lightboat.extra.big_file').clear()
  require('lightboat.extra.buffer').clear()
  require('lightboat.extra.rep_move').clear()
  require('lightboat.extra.line_wise').clear()
  require('lightboat.extra.project').clear()
end

M.setup = util.setup_check_wrap('lightboat.extra', function()
  require('lightboat.extra.big_file').setup()
  require('lightboat.extra.buffer').setup()
  require('lightboat.extra.rep_move').setup()
  require('lightboat.extra.line_wise').setup()
  require('lightboat.extra.project').setup()
end, M.clear)

return M
