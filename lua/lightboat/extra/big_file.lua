local M = {}
local util = require('lightboat.util')
local buffer = util.buffer
local config = require('lightboat.config')
local c
local group

--- Check if the buffer is a big file.
--- @param buf number? The buffer number, defaults to the current buffer.
--- @return boolean True if the buffer is a big file, false otherwise.
function M.is_big_file(buf)
  if not c or not c.enabled then return false end
  buf = buffer.normalize_buf(buf)
  local buf_size
  local file_name = vim.api.nvim_buf_get_name(buf)
  if not vim.bo[buf].modified and buffer.is_file(file_name) then
    buf_size = vim.fn.getfsize(file_name)
  else
    buf_size = buffer.get_buf_size(buf)
  end
  local line_count = vim.api.nvim_buf_line_count(buf)
  return c.big_file_total and buf_size > c.big_file_total
    or c.big_file_avg_line and buf_size > c.big_file_avg_line * line_count
end

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.extra.big_file', function()
  c = config.get().extra.big_file
  if not c.enabled then return nil end
  group = vim.api.nvim_create_augroup('LightBoatBigFile', {})
  local origin = {
    incsearch = nil,
    signcolumn = nil,
  }
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'BufEnter', 'FileType' }, {
    group = group,
    callback = function(ev)
      local is_big = M.is_big_file(ev.buf)
      if is_big then
        origin.incsearch = vim.o.incsearch
        origin.signcolumn = vim.o.signcolumn
        vim.o.incsearch = false
        vim.o.signcolumn = 'no'
      else
        if origin.incsearch then vim.o.incsearch = origin.incsearch end
        if origin.signcolumn then vim.o.signcolumn = origin.signcolumn end
      end
      vim.api.nvim_exec_autocmds('User', { pattern = 'BigFileDetector', data = is_big })
    end,
  })
end, M.clear)

return M
