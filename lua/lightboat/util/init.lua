local M = {
  search = require('lightboat.util.search'),
  buffer = require('lightboat.util.buffer'),
  key = require('lightboat.util.key'),
  network = require('lightboat.util.network'),
  git = require('lightboat.util.git'),
  log = require('lightboat.util.log'),
}

-- HACK:
-- Better way to do this?
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
    vim.schedule(
      function()
        vim.notify('Expected a table or string, got: ' .. type(value), vim.log.levels.ERROR, { title = 'LightBoat' })
      end
    )
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
      if require('lightboat.extra.big_file').is_big_file() then return end
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

-- HACK:
-- Find a better way to check if we are inside some types
--- @param types string[]
--- @return boolean|nil
--- Returns true if the cursor is inside a block of the specified types,
--- false if not, or nil if unable to determine.
function M.inside_block(types)
  local node_under_cursor = vim.treesitter.get_node()
  local parser = vim.treesitter.get_parser(nil, nil, { error = false })
  if not parser or not node_under_cursor then return nil end
  local query = vim.treesitter.query.get(parser:lang(), 'highlights')
  if not query then return nil end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  for id, node, _ in query:iter_captures(node_under_cursor, 0, row, row + 1) do
    for _, t in ipairs(types) do
      if query.captures[id]:find(t) then
        local start_row, start_col, end_row, end_col = node:range()
        if start_row <= row and row <= end_row then
          if start_row == row and end_row == row then
            if start_col <= col and col <= end_col then return true end
          elseif start_row == row then
            if start_col <= col then return true end
          elseif end_row == row then
            if col <= end_col then return true end
          else
            return true
          end
        end
      end
    end
  end
  return false
end

function M.clear_color_detection()
  cache = {}
  if color_group then
    vim.api.nvim_del_augroup_by_id(color_group)
    color_group = nil
  end
end

function M.reverse_list(list)
  if not list or #list == 0 then return list end
  local reversed = {}
  for i = #list, 1, -1 do
    table.insert(reversed, list[i])
  end
  return reversed
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
  if not name then
    -- HACK:
    -- As to nvim 0.12 { error = false } is not needed, remove this when nvim 0.12 is released
    return vim.treesitter.get_parser(nil, nil, { error = false }) ~= nil
  end
  return vim.treesitter.query.get(vim.treesitter.language.get_lang(vim.bo.filetype), name) ~= nil
end

function M.ensure_plugin(name)
  if not _G.plugin_loaded[name] then require(name) end
end

return M
