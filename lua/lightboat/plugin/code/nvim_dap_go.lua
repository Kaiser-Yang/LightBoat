local util = require('lightboat.util')
local M = {}

local spec = {
  'leoluz/nvim-dap-go',
  ft = { 'go', 'gomod', 'gowork', 'gotmpl' },
  cond = not vim.g.vscode,
  enabled = vim.fn.executable('go') == 1 and vim.fn.executable('dlv') == 1,
  opts = {},
}

function M.clear() end

function M.spec() return spec end

M.setup = util.setup_check_wrap('lightboat.plugin.code.nvim_dap_go', function() return spec end, M.clear)

return M
