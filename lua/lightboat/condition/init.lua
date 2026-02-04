local M = {}
local util = require('lightboat.util')

---@param filetype string|string[]
---@return boolean
function M.filetype(filetype) return vim.tbl_contains(util.ensure_list(filetype), vim.bo.filetype) end

---@param key string|string[]
---@return boolean
function M.last_key(key)
  local last_key = util.key.last_key()
  if last_key == nil then return false end
  last_key = util.key.termcodes(last_key)
  for _, k in ipairs(util.ensure_list(key)) do
    k = util.key.termcodes(k)
    if last_key:match(k .. '$') then return true end
  end
  return false
end

function M.treesitter_available()
  -- HACK:
  -- As to nvim 0.12 { error = false } is not needed, remove this when nvim 0.12 is released
  return vim.treesitter.get_parser(nil, nil, { error = false }) ~= nil
end

function M.completion_menu_visible() return require('blink.cmp').is_menu_visible() end
function M.snippet_active() return require('blink.cmp').snippet_active() end
function M.documentation_visible() return require('blink.cmp').is_documentation_visible() end
function M.signature_visible() return require('blink.cmp').is_signature_visible() end

return M
