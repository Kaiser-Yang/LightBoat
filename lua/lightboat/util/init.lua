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
function M.get_light_boat_root() return (vim.env.LAZY_PATH or vim.fn.stdpath('data') .. '/lazy') .. '/LightBoat' end

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

function M.resolve_opts(opts, inclusive_keys)
  opts = M.ensure_list(opts)
  local res = vim.deepcopy(opts)
  for k, v in pairs(opts) do
    if not inclusive_keys or inclusive_keys[k] then
      res[k] = M.get(v)
      if type(res[k]) == 'table' then res[k] = M.resolve_opts(res[k], inclusive_keys and inclusive_keys[k] or nil) end
    end
  end
  return res
end

local cache = {}
local color_group
function M.start_to_detect_color()
  if vim.fn.executable('rg') == 0 or color_group then return end
  color_group = vim.api.nvim_create_augroup('LightBoatColorDetection', {})
  vim.api.nvim_create_autocmd('User', {
    group = color_group,
    pattern = 'LazyLoad',
    callback = function(ev)
      if ev.data ~= 'nvim-highlight-colors' then return end
      M.clear_color_detection()
    end,
  })
  vim.api.nvim_create_autocmd('BufUnload', {
    group = color_group,
    callback = function(ev)
      local file = vim.api.nvim_buf_get_name(ev.buf)
      cache[file] = nil
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
    group = color_group,
    callback = function(ev)
      if require('lightboat.extra.big_file').is_big_file(ev.buf) then return end
      local file = vim.api.nvim_buf_get_name(ev.buf)
      if file == '' then return end
      local current_mtime = vim.fn.getftime(file)
      if cache[file] and cache[file] == current_mtime then return end
      cache[file] = current_mtime
      local patterns = {
        [[#(?:[0-9a-fA-F]{3,4}){1,2}\b]],
        [[\b(?:rgb|rgba|hsl|hsla)\s*\([^)]+\)]],
        [[var\(--[a-zA-Z0-9\-]+\)]],
        [[\b(?:text|bg|border|from|to|via|ring|stroke|fill|shadow|outline|accent|caret|divide|decoration|underline|overline|placeholder|selection|indigo|rose|pink|fuchsia|purple|violet|blue|sky|cyan|teal|emerald|green|lime|yellow|amber|orange|red|stone|neutral|zinc|gray|slate)-(?:[a-z]+-)?[0-9]{2,3}\b]],
      }
      local args = { '--color=never', '--no-heading', '--with-filename', '--max-count=1' }
      for _, pat in ipairs(patterns) do
        table.insert(args, '-e')
        table.insert(args, pat)
      end
      table.insert(args, file)

      vim.system({ 'rg', unpack(args) }, { text = true }, function(res)
        if res.code == 0 and res.stdout and res.stdout ~= '' then
          vim.schedule(function()
            M.clear_color_detection()
            vim.api.nvim_exec_autocmds('User', { pattern = 'ColorDetected' })
          end)
        end
      end)
    end,
  })
end

function M.clear_color_detection()
  cache = {}
  if color_group then
    vim.api.nvim_del_augroup_by_id(color_group)
    color_group = nil
  end
end

function M.set_hls(hls)
  for _, hl in ipairs(hls) do
    vim.api.nvim_set_hl(unpack(hl))
  end
end

return M
