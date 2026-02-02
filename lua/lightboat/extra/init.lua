local util = require('lightboat.util')
local M = {}

function M.clear()
  -- require('lightboat.extra.fold_sign').clear()
  require('lightboat.extra.command').clear()
  require('lightboat.extra.big_file').clear()
end

M.setup = util.setup_check_wrap('lightboat.extra', function()
  require('lightboat.extra.big_file').setup()
  require('lightboat.extra.command').setup()
  -- require('lightboat.extra.fold_sign').setup()
end, M.clear)

return M
