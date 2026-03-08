-- TODO:
-- completion for dap commands
local M = {}
--- Wrap a function to prompt for input and execute a callback with the input.
--- If the input is empty, it will notify the user and abort the operation.
--- @param prompt string The prompt message to display.
--- @param callback function The callback function to execute with the input.
--- @return function A wrapped function that prompts for input and executes the callback.
local function input_check_wrap(prompt, callback)
  return function()
    local input = vim.fn.input(prompt)
    if not input or input:match('^%s*$') then
      vim.notify('Input cannot be empty. Operation aborted.', vim.log.levels.WARN)
      return
    end
    callback(input)
  end
end

local function has_neo_tree() return buffer.get_win_with_filetype('neo%-tree')[1] ~= nil end

function M.dap_ui_toggle()
  local dap_ui = require('dapui')
  local dap_win_num = #buffer.get_win_with_filetype('dap')
  if dap_win_num < 6 then
    if dap_win_num ~= 0 then dap_ui.close() end
    if has_neo_tree() then require('neo-tree.command').execute({ action = 'close' }) end
    dap_ui.open({ reset = true })
  else
    dap_ui.close()
  end
end

M.set_condition_breakpoint = input_check_wrap(
  'Breakpoint Condition: ',
  function(input) require('dap').set_breakpoint(input) end
)

M.eval_expression = input_check_wrap('Evaluate Expression: ', function(input) require('dapui').eval(input) end)

M.set_log_point = input_check_wrap(
  'Log point message: ',
  function(input) require('dap').set_breakpoint(nil, nil, input) end
)

local has_last = false
function M.continue_or_run_last()
  local dap = require('dap')
  local session = dap.session()
  if session or not has_last then
    dap.continue()
  else
    dap.run_last()
  end
end

local operation = {
  ['<leader>du'] = M.dap_ui_toggle,
  ['<leader>db'] = function() require('dap').toggle_breakpoint() end,
  ['<leader>dB'] = M.set_condition_breakpoint,
  ['<leader>dc'] = function() require('persistent-breakpoints.api').clear_all_breakpoints() end,
  ['<leader>df'] = function() require('dapui').float_element() end,
  ['<leader>de'] = M.eval_expression,
  ['<leader>dt'] = function()
    if vim.bo.filetype == 'java' then
      local ok, jdtls = pcall(require, 'jdtls')
      if not ok then
        vim.notify('jdtls not found, please install it first.', vim.log.levels.WARN)
        return
      end
      jdtls.test_nearest_method()
    else
      vim.notify('Not support for current filetype: ' .. vim.bo.filetype, vim.log.levels.WARN)
    end
  end,
  ['<leader>dl'] = M.set_log_point,
  ['<f4>'] = function() require('dap').terminate() end,
  ['<f5>'] = M.continue_or_run_last,
  ['<f6>'] = function() require('dap').restart() end,
  ['<f9>'] = function() require('dap').step_back() end,
  ['<f10>'] = function() require('dap').step_over() end,
  ['<f11>'] = function() require('dap').step_into() end,
  ['<f12>'] = function() require('dap').step_out() end,
  require('dap.ui.widgets').hover(),
}
