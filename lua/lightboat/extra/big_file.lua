local M = {}
local util = require('lightboat.util')
local group

--- Check if current buffer is a big file.
function M.is_big_file()
  local _size = util.buffer.buffer_size()
  local line_count = vim.api.nvim_buf_line_count(0)
  local limit = type(vim.b.big_file_limit) == 'number' and vim.b.big_file_limit
    or type(vim.g.big_file_limit) == 'number' and vim.g.big_file_limit
  local average_every_line = type(vim.b.big_file_average_every_line) == 'number'
      and vim.b.big_file_average_every_line
    or type(vim.g.big_file_average_every_line) == 'number' and vim.g.big_file_average_every_line
  return type(limit) == 'number' and _size > limit
    or type(average_every_line) == 'number' and _size > average_every_line * line_count
end

M.setup = function()
  group = vim.api.nvim_create_augroup('LightBoatBigFile', {})
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'BufRead', 'FileChangedShell' }, {
    group = group,
    callback = function(ev)
      if vim.b.big_file_status == nil then vim.b.big_file_status = false end
      local is_big = M.is_big_file()
      if is_big ~= vim.b.big_file_status then
        vim.b.big_file_status = is_big
        vim.api.nvim_exec_autocmds('User', { pattern = 'BigFileStatusChanged' })
        if type(vim.b.big_file_on_changed) == 'function' then
          vim.schedule(function() vim.b.big_file_on_changed(ev.buf, is_big) end)
        elseif type(vim.g.big_file_on_changed) == 'function' then
          vim.schedule(function() vim.g.big_file_on_changed(ev.buf, is_big) end)
        end
      end
    end,
  })
end

return M
