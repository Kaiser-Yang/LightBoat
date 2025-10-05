local util = require('lightboat.util')
local log = util.log
local config = require('lightboat.config')
local c
local group

local operation = {
  ['<leader>R'] = '<cmd>OverseerRun<cr>',
}

local spec = {
  'stevearc/overseer.nvim',
  cmd = {
    'OverseerOpen',
    'OverseerClose',
    'OverseerToggle',
    'OverseerSaveBundle',
    'OverseerLoadBundle',
    'OverseerDeleteBundle',
    'OverseerRunCmd',
    'OverseerRun',
    'OverseerInfo',
    'OverseerBuild',
    'OverseerQuickAction',
    'OverseerTaskAction',
    'OverseerClearCache',
  },
  cond = not vim.g.vscode,
  config = function(_, opts)
    local overseer = require('overseer')
    overseer.setup(opts)
    local lualine = require('lualine')
    local lua_line_config = require('lualine.config').get_config()
    table.insert(lua_line_config.sections.lualine_x, 1, {
      'overseer',
      label = '', -- Prefix for task counts
      colored = true, -- Color the task icons and counts
      unique = false, -- Unique-ify non-running task count by name
      name = nil, -- List of task names to search for
      name_not = false, -- When true, invert the name search
      status = nil, -- List of task statuses to display
      status_not = false, -- When true, invert the status search
      fmt = require('lightboat.plugin.ui.lualine').disable_in_ft_wrap('dap'),
      symbols = {
        [overseer.STATUS.FAILURE] = 'F:',
        [overseer.STATUS.CANCELED] = 'C:',
        [overseer.STATUS.SUCCESS] = 'S:',
        [overseer.STATUS.RUNNING] = 'R:',
      },
    })
    vim.api.nvim_create_user_command('OverseerRestartLast', function()
      local tasks = overseer.list_tasks({ recent_first = true })
      if vim.tbl_isempty(tasks) then
        vim.notify('No tasks found', vim.log.levels.WARN)
      else
        overseer.run_action(tasks[1], 'restart')
      end
    end, {})
    lualine.setup(lua_line_config)
    log.debug('Overseer loaded')
  end,
  keys = {},
}

local M = {}

function M.spec() return spec end

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  c = nil
  spec.keys = {}
end

M.setup = util.setup_check_wrap('lightboat.plugin.code.overseer', function()
  if vim.g.vscode then return spec end
  c = config.get().overseer
  spec.enabled = c.enabled
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  group = vim.api.nvim_create_augroup('LightBoatOverseer', {})
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'OverseerForm',
    callback = function() util.key.set('n', '<esc>', 'q', { remap = true, buffer = true }) end,
  })
  return spec
end, M.clear)

return M
