local M = {
  buffer = require('lightboat.util.buffer'),
  key = require('lightboat.util.key'),
  git = require('lightboat.util.git'),
}

function M.get_light_boat_root() return M.lazy_path() .. '/LightBoat' end

function M.lazy_path() return vim.fn.stdpath('data') .. '/lazy' end

function M.ensure_list(value)
  if type(value) == 'table' then
    return value
  elseif type(value) == 'string' or type(value) == 'function' then
    return { value }
  elseif not value then
    return {}
  else
    vim.notify('Expected a table or string, got: ' .. type(value), vim.log.levels.ERROR, { title = 'LightBoat' })
  end
end

--- Check if the current file is in the possible config directory.
function M.in_config_dir()
  local paths = { vim.fn.expand('%:p'), vim.fn.getcwd() }
  for _, path in ipairs(paths) do
    if
      path:find('nvim')
      or path:find('LightBoat')
      or path:find('lightboat')
      or path:find('dotfile')
      or path:sub(1, #M.lazy_path()) == M.lazy_path()
      or path:sub(1, #vim.fn.stdpath('config')) == vim.fn.stdpath('config')
    then
      return true
    end
  end
  return false
end

function M.toggle_notify(name, state, opts)
  if state then
    vim.notify('[' .. name .. ']: Enabled', vim.log.levels.INFO, opts)
  else
    vim.notify('[' .. name .. ']: Disabled', vim.log.levels.INFO, opts)
  end
end

function M.get(v, ...)
  if type(v) == 'function' then return v(...) end
  return v
end

function M.ensure_function(name)
  if type(name) == 'function' then return name end
  return function() return name end
end

--- Copied from nvim-treesitter-textobjects.select
--- @param start_row integer 0 indexed
--- @param start_col integer 0 indexed
--- @param end_row integer 0 indexed
--- @param end_col integer 0 indexed, exclusive
--- @param selection_mode string
function M.update_selection(start_row, start_col, end_row, end_col, selection_mode)
  selection_mode = selection_mode or 'v'

  -- enter visual mode if normal or operator-pending (no) mode
  -- Why? According to https://learnvimscriptthehardway.stevelosh.com/chapters/15.html
  --   If your operator-pending mapping ends with some text visually selected, Vim will operate on that text.
  --   Otherwise, Vim will operate on the text between the original cursor position and the new position.
  local mode = vim.api.nvim_get_mode()
  selection_mode = vim.api.nvim_replace_termcodes(selection_mode, true, true, true)
  if mode.mode ~= selection_mode then vim.cmd.normal({ selection_mode, bang = true }) end

  -- end positions with `col=0` mean "up to the end of the previous line, including the newline character"
  if end_col == 0 then
    end_row = end_row - 1
    -- +1 is needed because we are interpreting `end_col` to be exclusive afterwards
    end_col = #vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, true)[1] + 1
  end

  local end_col_offset = 1
  if selection_mode == 'v' and vim.o.selection == 'exclusive' then end_col_offset = 0 end
  end_col = end_col - end_col_offset

  -- Position is 1, 0 indexed.
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  vim.cmd('normal! o')
  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
end

local plugin_cache = nil
--- @param name string
--- @return boolean
function M.plugin_available(name)
  if plugin_cache == nil then
    plugin_cache = {}
    for _, plugin in pairs(require('lazy').plugins()) do
      plugin_cache[plugin.name] = true
    end
  end
  if not plugin_cache[name] then plugin_cache[name] = false end
  return plugin_cache[name]
end

--- @type table<string, function>
local repmove = {}
--- @param previous string|function
--- @param next string|function
--- @param comma? string|function
--- @param semicolon? string|function
--- @return table<function>
function M.ensure_repmove(previous, next, comma, semicolon, rp)
  rp = rp or repmove
  if not rp[previous] or not rp[next] then
    if not M.plugin_available('repmove.nvim') then
      rp[previous], rp[next] = M.ensure_function(previous), M.ensure_function(next)
    else
      rp[previous], rp[next] = require('repmove').make(previous, next, comma, semicolon)
    end
  end
  return { rp[previous], rp[next] }
end

function M.treesitter_available(name)
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  if lang == nil then return false end
  return vim.treesitter.query.get(lang, name) ~= nil
end

function M.in_macro_recording() return vim.fn.reg_recording() ~= '' end

function M.in_macro_executing() return vim.fn.reg_executing() ~= '' end

function M.in_macro() return M.in_macro_recording() or M.in_macro_executing() end

return M
