local M = {}
--- @param mode string|string[]
--- @return boolean
function M.has_map(mode, lhs)
  local _has_map = function(m)
    for _, map in ipairs(vim.api.nvim_get_keymap(m)) do
      if map.lhs == lhs or map.lhsraw == lhs or map.lhsrawalt == lhs then return true end
    end
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, m)) do
      if map.lhs == lhs or map.lhsraw == lhs or map.lhsrawalt == lhs then return true end
    end
    return false
  end
  local util = require('lightboat.util')
  for _, m in ipairs(util.ensure_list(mode)) do
    if _has_map(m) then return true end
  end
  return false
end

--- @type string?
local last_key = nil
vim.on_key(function(key, typed) last_key = typed or key end, nil)
function M.last_key() return last_key end

--- @param keys string
--- @param mode string
--- @param replace_keycodes boolean?
function M.feedkeys(keys, mode, replace_keycodes)
  local termcodes = keys
  if replace_keycodes or replace_keycodes == nil then
    termcodes = vim.api.nvim_replace_termcodes(keys, true, true, true)
  end
  vim.api.nvim_feedkeys(termcodes, mode, false)
end

--- @param keys string
--- @return string
function M.termcodes(keys) return vim.api.nvim_replace_termcodes(keys, true, true, true) end

return M
