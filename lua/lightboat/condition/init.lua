local M = {}
local util = require('lightboat.util')

---@param filetype string|string[]
---@return boolean
function M.filetype(filetype) return vim.tbl_contains(util.ensure_list(filetype), vim.bo.filetype) end
---@param filetype string|string[]
---@return boolean
function M.not_filetype(filetype) return not M.filetype(filetype) end

---@param filetype string|string[]
---@return function
function M.filetype_wrap(filetype)
  return function() return M.filetype(filetype) end
end

---@param filetype string|string[]
---@return function
function M.not_filetype_wrap(filetype)
  return function() return M.not_filetype(filetype) end
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

function M.treesitter_available()
  -- HACK:
  -- As to nvim 0.12 { error = false } is not needed, remove this when nvim 0.12 is released
  return vim.treesitter.get_parser(nil, nil, { error = false }) ~= nil
end

function M.completion_menu_visible() return require('blink.cmp').is_menu_visible() end
function M.completion_menu_not_visible() return not M.completion_menu_visible() end
function M.completion_item_selected() return M.completion_menu_visible() and require('blink.cmp').get_selected_item() ~= nil end
function M.snippet_active() return require('blink.cmp').snippet_active() end
function M.documentation_visible() return require('blink.cmp').is_documentation_visible() end
function M.signature_visible() return require('blink.cmp').is_signature_visible() end
function M.signature_not_visible() return not M.signature_visible() end
function M.git_executable() return vim.fn.executable('git') == 1 end
function M.is_git_repository() return util.git.is_git_repository() end

return M
