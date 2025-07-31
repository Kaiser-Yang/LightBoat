local util = require('lightboat.util')
local buffer = util.buffer
return {
  {
    name = 'Launch file',
    type = 'codelldb',
    request = 'launch',
    program = function()
      if buffer.is_file(vim.g.path_to_executable) then return vim.g.path_to_executable end
      local res = vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
      if buffer.is_file(res) then vim.g.path_to_executable = res end
      return vim.g.path_to_executable or ''
    end,
    cwd = '${workspaceFolder}',
  },
  {
    name = 'Attach to process',
    type = 'codelldb',
    request = 'attach',
    pid = function()
      if vim.g.process_id then return vim.g.process_id end
      local dap = require('dap')
      if vim.g.process_name then return dap.utils.pick_process({ filter = vim.g.process_name }) end
      local id_or_name =
        vim.fn.input('Process ID or Executable name (filter): ', vim.fn.getcwd() .. '/', 'file')
      -- remove leading and trailing spaces
      id_or_name = id_or_name:gsub('^%s*(.-)%s*$', '%1')
      if tonumber(id_or_name) then
        vim.g.process_id = tonumber(id_or_name)
        return vim.g.process_id
      elseif buffer.is_file(id_or_name) then
        vim.g.process_name = id_or_name
      end
      return dap.utils.pick_process({ filter = vim.g.process_name })
    end,
    cwd = '${workspaceFolder}',
  },
}
