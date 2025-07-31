local M = {
  search = require('lightboat.util.search'),
  lfu = require('lightboat.util.lfu'),
  lru = require('lightboat.util.lru'),
  buffer = require('lightboat.util.buffer'),
  key = require('lightboat.util.key'),
  network = require('lightboat.util.network'),
  git = require('lightboat.util.git'),
  log = require('lightboat.util.log'),
}

-- HACK:
-- Better way to do this?
function M.get_light_boat_root()
  return (vim.env.LAZY_PATH or vim.fn.stdpath('data') .. '/lazy') .. '/LightBoat'
end

--- Setup plugins for LightBoat.
--- @param plugins table A table of plugin configurations.
--- @param name string The name used for notifications
--- @return ... Returns the results of the setup functions for each plugin.
function M.setup_plugins(plugins, name)
  local res = {}
  for _, plugin in pairs(plugins) do
    if type(plugin) == 'table' and plugin.setup then
      ---@type any[]
      local result = { pcall(plugin.setup) }
      local ok = result[1] --- @type boolean
      if ok then
        for i = 2, #result do
          if type(result[i][1]) == 'string' then
            M.log.debug(vim.inspect(result[i]))
            table.insert(res, result[i])
          else
            for _, v in ipairs(result[i]) do
              M.log.debug(vim.inspect(v))
              table.insert(res, v)
            end
          end
        end
      else
        local error = result[2]
        vim.notify('[' .. name .. ']: ' .. vim.inspect(error), vim.log.levels.ERROR)
      end
    end
  end
  return unpack(res)
end

--- Clear plugins for LightBoat.
--- @param plugins table A table of plugin configurations.
--- @param name string The name used for notifications
function M.clear_plugins(plugins, name)
  for _, plugin in pairs(plugins) do
    if type(plugin) == 'table' and plugin.clear then
      local ok, error = pcall(plugin.clear)
      if not ok then vim.notify('[' .. name .. ']: ' .. vim.inspect(error), vim.log.levels.ERROR) end
    end
  end
end

function M.ensure_list(value)
  if type(value) == 'table' then
    return value
  elseif type(value) == 'string' then
    return { value }
  elseif value == nil then
    return {}
  else
    vim.notify('Expected a table or string, got: ' .. type(value), vim.log.levels.ERROR)
  end
end

local did_setup = {}
--- @generic TCallback: fun(...)
--- @param name string
--- @param setup TCallback
--- @param clear fun()
--- @return TCallback
function M.setup_check_wrap(name, setup, clear)
  return function(...)
    if did_setup[name] then clear() end
    did_setup[name] = true
    return setup(...)
  end
end

--- Check if the current file is in the possible config directory.
function M.in_config_dir()
  local paths = { vim.fn.expand('%:p'), vim.fn.getcwd() }
  for _, path in ipairs(paths) do
    if path:find('nvim') or path:find('LightBoat') or path:find('lightboat') or path:find('dotfile') then
      return true
    end
  end
  return false
end

function M.get(opt, ...)
  if type(opt) == 'function' then
    return opt(...)
  else
    return opt
  end
end

return M
