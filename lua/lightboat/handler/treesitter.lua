local u = require('lightboat.util')
local M = {}

local textobject_available = u.plugin_available('nvim-treesitter-textobjects')
--- @param direction 'next'|'previous'
--- @param position 'start'|'end'
function M.go_to(direction, position, query_string, query_group)
  if not textobject_available or u.buffer.big() then return false end
  vim.schedule_wrap(require('nvim-treesitter-textobjects.move')['goto_' .. direction .. '_' .. position])(
    query_string,
    query_group
  )
  -- HACK:
  -- We do not know if the operation is successful or not, so just return true
  return true
end

return M
