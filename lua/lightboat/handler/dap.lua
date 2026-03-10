local M = {}
local u = require('lightboat.util')

local function check()
  if not u.plugin_available('nvim-dap') then
    vim.notify('nvim-dap is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end

local function check_dap_view()
  if not u.plugin_available('nvim-dap-view') then
    vim.notify('nvim-dap-view is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
end

function M.toggle_dap_view()
  if not check_dap_view() then return false end
  require('dap-view').toggle()
  return true
end

function M.restart_or_run_last()
  if not check() then return false end
  local dap = require('dap')
  if dap.session() then
    dap.restart()
  else
    dap.run_last()
  end
  return true
end

M.set_condition_breakpoint = function()
  if not check() then return false end
  vim.ui.input({ prompt = 'Condition Breakpoint' }, function(input)
    if input and input ~= '' then require('dap').set_breakpoint(input) end
  end)
  return true
end

M.set_log_point = function()
  if not check() then return false end
  vim.ui.input({ prompt = 'Log Point Message' }, function(input)
    if input and input ~= '' then require('dap').set_breakpoint(nil, nil, input) end
  end)
  return true
end

return M
