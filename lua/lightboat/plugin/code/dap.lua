-- TODO:
-- completion for dap commands
local util = require('lightboat.util')
local key = util.key
local log = util.log
local buffer = util.buffer
local M = {}
local config = require('lightboat.config')
local c

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
  ['<leader>b'] = function() require('dap').toggle_breakpoint() end,
  ['<leader>B'] = M.set_condition_breakpoint,
  ['<leader>df'] = function() require('dapui').float_element() end,
  ['<leader>de'] = M.eval_expression,
  ['<leader>dl'] = M.set_log_point,
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
  ['<f4>'] = function() require('dap').terminate() end,
  ['<f5>'] = M.continue_or_run_last,
  ['<f6>'] = function() require('dap').restart() end,
  ['<f9>'] = function() require('dap').step_back() end,
  ['<f10>'] = function() require('dap').step_over() end,
  ['<f11>'] = function() require('dap').step_into() end,
  ['<f12>'] = function() require('dap').step_out() end,
}
local spec = {
  { 'mfussenegger/nvim-dap', dependencies = { 'nvim-lua/plenary.nvim' }, lazy = true },
  { 'theHamsta/nvim-dap-virtual-text', lazy = true, opts = {} },
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'nvim-neotest/nvim-nio', 'nvim-lua/plenary.nvim' },
    opts = {
      -- TODO: better key mappings
      mappings = {
        edit = { 'e' },
        expand = { '<2-LeftMouse>', 'l', 'h' },
        open = { '<cr>', 'o' },
        remove = { 'x', 'd' },
        repl = { 'r' },
        toggle = { 't' },
      },
      floating = { mappings = { close = { 'q', '<esc>', '<c-c>' } } },
      layouts = {
        {
          elements = {
            { id = 'scopes', size = 0.25 },
            { id = 'breakpoints', size = 0.25 },
            { id = 'stacks', size = 0.25 },
            { id = 'watches', size = 0.25 },
          },
          position = 'left',
          size = math.max(30, math.ceil(vim.o.columns * 0.14)),
        },
        {
          elements = {
            { id = 'console', size = 0.5 },
            { id = 'repl', size = 0.5 },
          },
          position = 'bottom',
          size = math.max(8, math.ceil(vim.o.lines * 0.2)),
        },
      },
    },
    keys = {},
    config = function(_, opts)
      local dap = require('dap')
      local dapui = require('dapui')
      local json = require('plenary.json')
      local vscode = require('dap.ext.vscode')
      local before_start = function()
        -- Lazy load nvim-dap-virtual-text when starting a new debug session
        if not has_last then
          require('nvim-dap-virtual-text')
          has_last = true
        end
        -- Close neo-tree to have better debugging experiences
        if has_neo_tree() then require('neo-tree.command').execute({ action = 'close' }) end
        dapui.open({ reset = true })
      end
      dapui.setup(opts)
      dap.listeners.before.attach.dapui_config = before_start
      dap.listeners.before.launch.dapui_config = before_start
      dap.adapters = vim.tbl_extend('force', dap.adapters, c.adapters)
      dap.configurations = vim.tbl_extend('force', dap.configurations, c.configurations)
      vscode.json_decode = function(str) return vim.json.decode(json.json_strip_comments(str)) end
      log.debug('Dap loaded')
    end,
  },
}

function M.spec() return spec end

function M.clear()
  assert(spec[3][1] == 'rcarriga/nvim-dap-ui')
  spec[3].keys = {}
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.code.dap', function()
  c = config.get().dap
  if not c.enabled then return nil end
  assert(spec[3][1] == 'rcarriga/nvim-dap-ui')
  spec[3].keys = key.get_lazy_keys(operation, c.keys)
  vim.api.nvim_set_hl(0, 'DapStopped', { fg = '#98C379' })
  vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = '#31353F' })
  vim.api.nvim_set_hl(0, 'DapBreakpointRejected', { fg = '#888888' })
  vim.api.nvim_set_hl(0, 'DapLogPoint', { fg = '#89dceb' })
  vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg = '#f38ba8' })
  vim.api.nvim_set_hl(0, 'DapBreakpointCondition', { fg = '#f9e2af' })
  vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DapStopped', linehl = 'DapStoppedLine' })
  vim.fn.sign_define('DapLogPoint', { text = '', texthl = 'DapLogPoint' })
  vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint' })
  vim.fn.sign_define('DapBreakpointRejected', { text = 'x', texthl = 'DapBreakpointRejected' })
  vim.fn.sign_define('DapBreakpointCondition', { text = '○', texthl = 'DapBreakpointCondition' })
  return spec
end, M.clear)

return M
