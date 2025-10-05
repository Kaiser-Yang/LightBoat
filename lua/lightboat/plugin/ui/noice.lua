local M = {}
local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local group

local operation = {
  ['<leader>sn'] = function()
    if not Snacks then return end
    require('noice.integrations.snacks').open(c.keys['<leader>sn'].opts)
  end,
}

local spec = {
  { 'rcarriga/nvim-notify', cond = not vim.g.vscode, lazy = true },
  {
    'folke/noice.nvim',
    -- HACK:
    -- The experience of notify is not good enough
    dependencies = { 'MunifTanjim/nui.nvim' },
    event = 'VeryLazy',
    cond = not vim.g.vscode,
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
        },
        signature = { enabled = false },
        documentation = { enabled = false },
      },
      presets = { long_message_to_split = true, lsp_doc_border = true },
      messages = { view_search = false },
      routes = {
        {
          filter = {
            any = {
              { event = 'msg_show', find = 'ServiceReady' },
              { event = 'msg_show', find = 'Starting Java Language Server' },
              { event = 'msg_show', find = 'Init%.%.%.' },
              { find = 'Error running git%-blame: fatal: unable to access' },
              { find = 'Error running git%-blame: ssh: connect to host' },
              { event = 'lsp', kind = 'progress', find = 'Building' },
              { event = 'lsp', kind = 'progress', find = 'Searching' },
              { event = 'lsp', kind = 'progress', find = 'Validate documents' },
              { event = 'lsp', kind = 'progress', find = 'Publish Diagnostics' },
              { event = 'lsp', kind = 'progress', mode = 'i' },
            },
          },
        },
      },
    },
    keys = {},
  },
}

function M.spec() return spec end

function M.clear()
  assert(spec[2][1] == 'folke/noice.nvim')
  spec[2].keys = {}
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.ui.noice', function()
  if vim.g.vscode then return spec end
  c = config.get().noice
  for _, s in ipairs(spec) do
    s.enabled = c.enabled
  end
  assert(spec[2][1] == 'folke/noice.nvim')
  spec[2].keys = util.key.get_lazy_keys(operation, c.keys)
  group = vim.api.nvim_create_augroup('LightBoatNoice', {})
  local macro_recording_status = false
  vim.api.nvim_create_autocmd('RecordingEnter', {
    group = group,
    callback = function()
      local msg = string.format('Recording @%s', vim.fn.reg_recording())
      macro_recording_status = true
      vim.notify(msg, nil, {
        title = 'Macro Recording',
        keep = function() return macro_recording_status end,
        timeout = 0,
      })
    end,
  })
  vim.api.nvim_create_autocmd('RecordingLeave', {
    group = group,
    callback = function() macro_recording_status = false end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'noice',
    group = group,
    callback = function() util.key.set('n', '<esc>', 'q', { remap = true, buffer = true }) end,
  })
  return spec
end, M.clear)

return M
