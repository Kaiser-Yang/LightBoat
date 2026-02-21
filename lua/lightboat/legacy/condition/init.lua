local util = require('lightboat.util')

---@class Cond
---@field private _conditions function[]
local Cond = {}
Cond.__index = Cond

---Create a new Cond instance
---@return Cond
function Cond.new()
  local self = setmetatable({}, Cond)
  self._conditions = {}
  return self
end

---Make Cond callable with ()
---@return Cond
setmetatable(Cond, {
  __call = function(cls) return cls.new() end,
})

---Make Cond instance callable to evaluate all conditions
---@return boolean
function Cond:__call()
  for _, condition in ipairs(self._conditions) do
    if not condition() then return false end
  end
  return true
end

---Create a copy of current instance
---@return Cond
function Cond:_copy()
  local copy = Cond.new()
  copy._conditions = vim.deepcopy(self._conditions)
  return copy
end

---Add a filetype condition
---@param filetype string|string[]
---@return Cond
function Cond:filetype(filetype)
  local copy = self:_copy()
  table.insert(copy._conditions, function() return vim.tbl_contains(util.ensure_list(filetype), vim.bo.filetype) end)
  return copy
end

---Add a not_filetype condition
---@param filetype string|string[]
---@return Cond
function Cond:not_filetype(filetype)
  local copy = self:_copy()
  local fc = Cond():filetype(filetype)
  table.insert(copy._conditions, function() return not fc() end)
  return copy
end

---Add a completion_menu_visible condition
---@return Cond
function Cond:completion_menu_visible()
  local copy = self:_copy()
  local cmp_installed = util.plugin_available('blink.cmp')
  copy:add(cmp_installed)
  table.insert(copy._conditions, function() return require('blink.cmp').is_menu_visible() end)
  return copy
end

---Add a completion_menu_not_visible condition
---@return Cond
function Cond:completion_menu_not_visible()
  local copy = self:_copy()
  local cmp_installed = util.plugin_available('blink.cmp')
  copy:add(cmp_installed)
  table.insert(copy._conditions, function() return not require('blink.cmp').is_menu_visible() end)
  return copy
end

---Add a completion_item_selected condition
---@return Cond
function Cond:completion_item_selected()
  local copy = self:_copy()
  local cmp_installed = util.plugin_available('blink.cmp')
  copy:add(cmp_installed)
  table.insert(copy._conditions, function()
    local blink = require('blink.cmp')
    return blink.is_menu_visible() and blink.get_selected_item() ~= nil
  end)
  return copy
end

---Add a snippet_active condition
---@return Cond
function Cond:snippet_active()
  local copy = self:_copy()
  local cmp_installed = util.plugin_available('blink.cmp')
  copy:add(cmp_installed)
  table.insert(copy._conditions, function() return require('blink.cmp').snippet_active() end)
  return copy
end

---Add a snippet_not_active condition
---@return Cond
function Cond:snippet_not_active()
  local copy = self:_copy()
  local cmp_installed = util.plugin_available('blink.cmp')
  copy:add(cmp_installed)
  table.insert(copy._conditions, function() return not require('blink.cmp').snippet_active() end)
  return copy
end

---Add a documentation_visible condition
---@return Cond
function Cond:documentation_visible()
  local copy = self:_copy()
  local cmp_installed = util.plugin_available('blink.cmp')
  copy:add(cmp_installed)
  table.insert(copy._conditions, function() return require('blink.cmp').is_documentation_visible() end)
  return copy
end

---Add a signature_visible condition
---@return Cond
function Cond:signature_visible()
  local copy = self:_copy()
  local cmp_installed = util.plugin_available('blink.cmp')
  copy:add(cmp_installed)
  table.insert(copy._conditions, function() return require('blink.cmp').is_signature_visible() end)
  return copy
end

---Add a signature_not_visible condition
---@return Cond
function Cond:signature_not_visible()
  local copy = self:_copy()
  local cmp_installed = util.plugin_available('blink.cmp')
  copy:add(cmp_installed)
  table.insert(copy._conditions, function() return not require('blink.cmp').is_signature_visible() end)
  return copy
end

---Add a executable condition
---@param name string
---@return Cond
function Cond:executable(name)
  local copy = self:_copy()
  table.insert(copy._conditions, function() return vim.fn.executable(name) == 1 end)
  return copy
end

---Add a is_git_repository condition
---@return Cond
function Cond:is_git_repository()
  local copy = self:_copy()
  table.insert(copy._conditions, function() return util.git.is_git_repository() end)
  return copy
end

---Add a has_conflict condition
---@return Cond
function Cond:has_conflict()
  local copy = self:_copy()
  table.insert(copy._conditions, function() return util.git.has_conflict() end)
  return copy
end

---Add a custom condition function
---@param custom_condition any
---@return Cond
function Cond:add(custom_condition)
  local copy = self:_copy()
  if type(custom_condition) == 'function' or (type(custom_condition) == 'table' and custom_condition.__call) then
    table.insert(copy._conditions, custom_condition)
  else
    table.insert(copy._conditions, function() return not not custom_condition end)
  end
  return copy
end

---Add a cursor not eol condition
---@return Cond
function Cond:cursor_not_eol()
  local copy = self:_copy()
  table.insert(copy._conditions, function()
    local mode = vim.api.nvim_get_mode().mode
    if mode:sub(1, 1) == 'c' then
      local col = vim.fn.getcmdpos() - 1
      local line = vim.fn.getcmdline()
      return col < #line
    end
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    return col < #line
  end)
  return copy
end

---Add a cursor not bol condition
---@return Cond
function Cond:cursor_not_bol()
  local copy = self:_copy()
  table.insert(copy._conditions, function()
    local mode = vim.api.nvim_get_mode().mode
    if mode:sub(1, 1) == 'c' then
      local col = vim.fn.getcmdpos() - 1
      return col > 0
    end
    local col = vim.api.nvim_win_get_cursor(0)[2]
    return col > 0
  end)
  return copy
end

---Add a cursor not fist_non_blank condition
---@return Cond
function Cond:cursor_not_first_non_blank()
  local copy = self:_copy()
  table.insert(copy._conditions, function()
    local mode = vim.api.nvim_get_mode().mode
    if mode:sub(1, 1) == 'c' then
      local col = vim.fn.getcmdpos() - 1
      local line = vim.fn.getcmdline()
      local first_non_blank = line:find('%S')
      if first_non_blank == nil then first_non_blank = #line + 1 end
      return col ~= first_non_blank - 1
    end
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    local first_non_blank = line:find('%S')
    if first_non_blank == nil then first_non_blank = #line + 1 end
    return col ~= first_non_blank - 1
  end)
  return copy
end

---Add a lsp_attached condition
---@return Cond
function Cond:lsp_attached()
  local copy = self:_copy()
  table.insert(copy._conditions, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end)
  return copy
end

return Cond
