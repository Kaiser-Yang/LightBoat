local util = require('lightboat.util')
local M = {}
local spec = {
  'zbirenbaum/copilot.lua',
  event = { { event = 'User', pattern = 'NetworkChecked' } },
  enabled = vim.fn.executable('node') == 1,
  opts = {
    panel = { enabled = false },
    suggestion = {
      auto_trigger = true,
      hide_during_completion = false,
      keymap = {
        accept = '<m-cr>',
        accept_word = '<m-f>',
        accept_line = '<c-f>',
        dismiss = '<c-c>',
        next = false,
        prev = false,
      },
    },
    filetypes = { ['*'] = true },
    copilot_node_command = 'node',
    server_opts_overrides = {},
  },
}
function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.ai.copilot', function() return spec end, M.clear)

return M
