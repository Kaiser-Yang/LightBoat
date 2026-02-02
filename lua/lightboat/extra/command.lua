local M = {}
local util = require('lightboat.util')
local config = require('lightboat.config')

local function load_list_to_arglist(is_quickfix)
  local cmd_type = is_quickfix and 'Quickfix' or 'Location'
  local list = is_quickfix and vim.fn.getqflist() or vim.fn.getloclist(0)

  local buffer_numbers = {}
  for _, item in ipairs(list) do
    local bufnr = item.bufnr
    if bufnr > 0 then buffer_numbers[bufnr] = vim.fn.bufname(bufnr) end
  end
  local filenames = vim.tbl_map(function(buf) return vim.fn.fnameescape(buf) end, vim.tbl_values(buffer_numbers))

  if #filenames == 0 then
    vim.notify(cmd_type .. ' list is empty', vim.log.levels.WARN)
    return
  end

  vim.cmd('args ' .. table.concat(filenames, ' '))
  vim.notify('Successfully loaded ' .. cmd_type .. ' list into arglist', vim.log.levels.INFO)
end
local command_ = {
  Qargs = {
    callback = function() load_list_to_arglist(true) end,
    opt = {
      nargs = 0,
      bar = true,
    },
  },
  Largs = {
    callback = function() load_list_to_arglist(false) end,
    opt = {
      nargs = 0,
      bar = true,
    },
  },
}

M.clear = function()
  for _, command in pairs(config.get().extra.command) do
    pcall(vim.api.nvim_del_user_command, command.name)
  end
end

M.setup = util.setup_check_wrap('lightboat.extra.command', function()
  for id, command in pairs(config.get().extra.command) do
    if command.enabled then vim.api.nvim_create_user_command(command.name, command_[id].callback, command_[id].opt) end
  end
end, M.clear)
return M
