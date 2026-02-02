local M = {}
local util = require('lightboat.util')

---@param filetype string|string[]
---@return boolean
function M.filetype(filetype) return vim.tbl_contains(util.ensure_list(filetype), vim.bo.filetype) end

---@param filetype string|string[]
function M.filetype_wrap(filetype)
  return function() return M.filetype(filetype) end
end

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

--- @param key string|string[]
--- @return fun(): boolean
function M.last_key_wrap(key)
  return function() return M.last_key(key) end
end
return M
