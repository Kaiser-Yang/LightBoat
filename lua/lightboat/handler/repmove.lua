local u = require('lightboat.util')
local repmove_available = u.plugin_available('repmove')

local M = {}

-- stylua: ignore start
function M.comma() if not repmove_available then return ',' end return require('repmove').comma() end
function M.semicolon() if not repmove_available then return ';' end return require('repmove').semicolon() end
function M.F() return u.ensure_repmove('F', 'f', ',', ';')[1]() end
function M.f() return u.ensure_repmove('F', 'f', ',', ';')[2]() end
function M.T() return u.ensure_repmove('T', 't', ',', ';')[1]() end
function M.t() return u.ensure_repmove('T', 't', ',', ';')[2]() end
function M.previous_misspelled() return u.ensure_repmove('[s', ']s')[1]() end
function M.next_misspelled() return u.ensure_repmove('[s', ']s')[2]() end
-- stylua: ignore end

return M
