local M = {}

--- Normalize the buffer number to its real buffer identity.
function M.normalize_buf(buf)
  buf = buf or 0
  if buf == 0 then buf = vim.api.nvim_get_current_buf() end
  return buf
end

function M.get_buf_size(buf)
  buf = M.normalize_buf(buf)
  local res = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf) - 1)
  -- Add size of the last line
  res = res + #vim.api.nvim_buf_get_lines(buf, -1, -1, false)
  return res
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

return M
