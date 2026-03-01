local M = {}
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

--- Normalize the tab page number to its real tab page identity.
--- @param tabpage number? The tab page number, defaults to the current tab page.
--- @return number The normalized tab page number.
function M.normalize_tabpage(tabpage)
  tabpage = tabpage or 0
  if tabpage == 0 then tabpage = vim.api.nvim_get_current_tabpage() end
  return tabpage
end

--- Get a list of windows of specific tab page with specific file types.
--- @param fts string|string[] A file type or a list of file types to match.
--- @param tabpage number? The tab page number to check, defaults to the current tab page.
--- @return number[] A list of window numbers that match the specified file types.
function M.get_win_with_filetype(fts, tabpage)
  local res = {}
  --- @type string[]
  fts = type(fts) == 'table' and fts or { fts }
  tabpage = M.normalize_tabpage(tabpage)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    for _, ft in ipairs(fts) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype:match(ft) then table.insert(res, win) end
    end
  end
  return res
end

--- Check if a given path is a file.
--- @param path string? The path to check.
--- @return boolean True if the path is a file, false otherwise.
function M.is_file(path)
  path = path and path or ''
  local fs_stat = vim.uv.fs_stat(path)
  return fs_stat and fs_stat.type == 'file'
end

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

return M
