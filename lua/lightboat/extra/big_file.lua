local M = {}
local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local group

--- Check if the buffer is a big file.
--- @param buffer integer? The buffer number, defaults to the current buffer.
--- @return boolean
function M.is_big_file(buffer)
  if not c.enabled then return false end
  buffer = util.buffer.normalize_buf(buffer)
  if not c or not c.enabled then return false end
  local buffer_size = util.buffer.buffer_size(buffer)
  local line_count = vim.api.nvim_buf_line_count(buffer)
  return c.big_file_total and buffer_size > c.big_file_total
    or c.big_file_average_line and buffer_size > c.big_file_average_line * line_count
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
  if not c.enabled then return end
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
        if origin.incsearch == nil then origin.incsearch = vim.o.incsearch end
        if origin.signcolumn == nil then origin.signcolumn = vim.o.signcolumn end
        vim.o.incsearch = false
        vim.o.signcolumn = 'no'
      else
        if origin.incsearch ~= nil then vim.o.incsearch = origin.incsearch end
        if origin.signcolumn ~= nil then vim.o.signcolumn = origin.signcolumn end
      end
      vim.api.nvim_exec_autocmds('User', { pattern = 'BigFileDetector', data = is_big })
    end,
  })
end, M.clear)

return M
