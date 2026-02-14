local M = {}

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
    vim.schedule(function() vim.notify(cmd_type .. ' list is empty', vim.log.levels.WARN, { title = 'LightBoat' }) end)
    return
  end

  vim.cmd('args ' .. table.concat(filenames, ' '))
  vim.schedule(
    function()
      vim.notify(
        'Successfully loaded ' .. cmd_type .. ' list into arglist',
        vim.log.levels.INFO,
        { title = 'LightBoat' }
      )
    end
  )
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

M.setup = function()
  -- vim.api.nvim_create_user_command(command.name, command_[id].callback, command_[id].opt)
end
return M
