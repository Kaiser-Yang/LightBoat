local util = require('lightboat.util')
local M = {}
local spec = {
  'zbirenbaum/copilot.lua',
  event = { { event = 'User', pattern = 'NetworkChecked' } },
  enabled = vim.fn.executable('node') == 1 and vim.fn.executable('curl') == 1,
  opts = {
    panel = { enabled = false },
    suggestion = {
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
    should_attach = function(bufnr)
      return require('lightboat.config.extra.buffer').is_visible_buffer(bufnr)
        and not require('lightboat.extra.big_file').is_big_file(bufnr)
    end,
  },
}
function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.ai.copilot', function() return spec end, M.clear)

return M
