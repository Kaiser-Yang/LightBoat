local M = {}
local u = require('lightboat.util')

function M.toggle_dap_view()
  local dap_view = require('dap-view')
  local dap_win_num = #u.buffer.get_win_with_filetype('dap%-view')
  if dap_win_num == 0 and _G.plugin_loaded['nvim-tree.lua'] then
    local tree = require('nvim-tree.api').tree
    if tree.is_visible() then tree.toggle() end
  end
  dap_view.toggle()
  return true
end

M.set_condition_breakpoint = function()
  vim.ui.input({ prompt = 'Condition Breakpoint' }, function(input)
    if input and input ~= '' then require('dap').set_breakpoint(input) end
  end)
  return true
end

M.set_log_point = function()
  vim.ui.input({ prompt = 'Log Point Message' }, function(input)
    if input and input ~= '' then require('dap').set_breakpoint(nil, nil, input) end
  end)
  return true
end

return M
