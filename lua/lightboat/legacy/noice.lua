local M = {}
local util = require('lightboat.util')
local c
local group

local operation = {
  ['<leader>sn'] = function()
    require('noice.integrations.snacks').open(c.keys['<leader>sn'].opts)
  end,
}

local spec = {
  -- HACK:
  -- The experience of notify is not good enough
  { 'rcarriga/nvim-notify', cond = not vim.g.vscode, lazy = true },
}

M.setup = util.setup_check_wrap('lightboat.plugin.ui.noice', function()
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
