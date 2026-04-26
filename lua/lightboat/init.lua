local M = {}

local function check_network()
  local sock = vim.uv.new_tcp()
  if not sock then return end
  local domain = '114.114.114.114'
  sock:connect(domain, 53, function(err)
    if sock then sock:close() end
    if err then return end
    vim.schedule(function() vim.api.nvim_exec_autocmds('User', { pattern = 'NetworkAvailable' }) end)
  end)
end

local setup_autocmd = function()
  vim.api.nvim_create_autocmd('User', {
    pattern = 'VeryLazy',
    once = true,
    callback = function()
      check_network()
    end,
  })
end

M.setup = function()
  setup_autocmd()
  pcall(function() require('vim._extui').enable({}) end)
end

return M
