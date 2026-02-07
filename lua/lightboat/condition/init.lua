local util = require('lightboat.util')

---@class Condition
---@field private conditions function[]
local Condition = {}
Condition.__index = Condition

--- Create a new Condition instance
---@return Condition
function Condition.new()
  local self = setmetatable({}, Condition)
  self.conditions = {}
  return self
end

--- Make Condition callable to evaluate all conditions
---@return boolean
function Condition:__call()
  for _, cond_fn in ipairs(self.conditions) do
    if not cond_fn() then
      return false
    end
  end
  return true
end

--- Add a condition to check filetype
---@param filetype string|string[]
---@return Condition
function Condition:filetype(filetype)
  table.insert(self.conditions, function()
    return vim.tbl_contains(util.ensure_list(filetype), vim.bo.filetype)
  end)
  return self
end

--- Add a condition to check not filetype
---@param filetype string|string[]
---@return Condition
function Condition:not_filetype(filetype)
  table.insert(self.conditions, function()
    return not vim.tbl_contains(util.ensure_list(filetype), vim.bo.filetype)
  end)
  return self
end

--- Add a condition to check last key
---@param key string|string[]
---@return Condition
function Condition:last_key(key)
  table.insert(self.conditions, function()
    local last_key = util.key.last_key()
    if last_key == nil then return false end
    last_key = util.key.termcodes(last_key)
    for _, k in ipairs(util.ensure_list(key)) do
      k = util.key.termcodes(k)
      if last_key:match(k .. '$') then return true end
    end
    return false
  end)
  return self
end

--- Add a condition to check if treesitter is available
---@return Condition
function Condition:treesitter_available()
  table.insert(self.conditions, function()
    -- HACK:
    -- As to nvim 0.12 { error = false } is not needed, remove this when nvim 0.12 is released
    return vim.treesitter.get_parser(nil, nil, { error = false }) ~= nil
  end)
  return self
end

--- Add a condition to check if completion menu is visible
---@return Condition
function Condition:completion_menu_visible()
  table.insert(self.conditions, function()
    return require('blink.cmp').is_menu_visible()
  end)
  return self
end

--- Add a condition to check if completion menu is not visible
---@return Condition
function Condition:completion_menu_not_visible()
  table.insert(self.conditions, function()
    return not require('blink.cmp').is_menu_visible()
  end)
  return self
end

--- Add a condition to check if completion item is selected
---@return Condition
function Condition:completion_item_selected()
  table.insert(self.conditions, function()
    return require('blink.cmp').is_menu_visible() and require('blink.cmp').get_selected_item() ~= nil
  end)
  return self
end

--- Add a condition to check if snippet is active
---@return Condition
function Condition:snippet_active()
  table.insert(self.conditions, function()
    return require('blink.cmp').snippet_active()
  end)
  return self
end

--- Add a condition to check if documentation is visible
---@return Condition
function Condition:documentation_visible()
  table.insert(self.conditions, function()
    return require('blink.cmp').is_documentation_visible()
  end)
  return self
end

--- Add a condition to check if signature is visible
---@return Condition
function Condition:signature_visible()
  table.insert(self.conditions, function()
    return require('blink.cmp').is_signature_visible()
  end)
  return self
end

--- Add a condition to check if signature is not visible
---@return Condition
function Condition:signature_not_visible()
  table.insert(self.conditions, function()
    return not require('blink.cmp').is_signature_visible()
  end)
  return self
end

--- Add a condition to check if git is executable
---@return Condition
function Condition:git_executable()
  table.insert(self.conditions, function()
    return vim.fn.executable('git') == 1
  end)
  return self
end

--- Add a condition to check if in a git repository
---@return Condition
function Condition:is_git_repository()
  table.insert(self.conditions, function()
    return util.git.is_git_repository()
  end)
  return self
end

--- Add a condition to check if a value is truthy
---@param value any
---@return Condition
function Condition:value(value)
  table.insert(self.conditions, function()
    return not not value
  end)
  return self
end

-- Make the module itself callable to create new instances
local M = setmetatable({}, {
  __call = function()
    return Condition.new()
  end
})

-- Export the new method for explicit instantiation
M.new = Condition.new

return M
