local M = {}
local util = require('lightboat.util')
local config = require('lightboat.config')
local group

--- Check if the buffer is a big file.
--- @param buffer integer? The buffer number, defaults to the current buffer.
--- @return boolean
function M.is_big_file(buffer)
  if not config.get().extra.big_file.enabled then return false end
  buffer = util.buffer.normalize_buf(buffer)
  local buffer_size = util.buffer.buffer_size(buffer)
  local line_count = vim.api.nvim_buf_line_count(buffer)
  return buffer_size > config.get().extra.big_file.total
    or buffer_size > config.get().extra.big_file.every_line * line_count
end

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
end

M.setup = util.setup_check_wrap('lightboat.extra.big_file', function()
  if not config.get().extra.big_file.enabled then return end
  group = vim.api.nvim_create_augroup('LightBoatBigFile', {})
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'BufEnter', 'BufRead' }, {
    group = group,
    callback = function(ev)
      if vim.b[ev.buf].big_file_status == nil then vim.b[ev.buf].big_file_status = false end
      local is_big = M.is_big_file(ev.buf)
      if is_big ~= vim.b[ev.buf].big_file_status then
        vim.b[ev.buf].big_file_status = is_big
        vim.api.nvim_exec_autocmds('User', { pattern = 'BigFileStatusChanged' })
        vim.schedule(function() config.get().extra.big_file.on_changed(ev.buf) end)
      end
    end,
  })
end, M.clear)

return M
