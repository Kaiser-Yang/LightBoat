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
  if not c.enabled then return false end
  buf = buffer.normalize_buf(buf)
  local fs_size
  if c.big_file_total then
    fs_size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
    if fs_size > c.big_file_total then return true end
  end
  if c.big_file_avg_line then
    fs_size = fs_size or vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
    local line_count = vim.api.nvim_buf_line_count(buf)
    if fs_size > c.big_file_avg_line * line_count then return true end
  end
  return false
end

--- Wrap a callback function to check if the file is too big before executing it.
function M.big_file_check_wrap(callback)
  return function(...)
    if M.is_big_file() then
      vim.notify('File is too big, and operation aborted', vim.log.levels.WARN)
      return
    end
    return callback(...)
  end
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
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(ev)
      if M.is_big_file(ev.buf) then vim.o.incsearch = false end
    end,
  })
end, M.clear)

return M
