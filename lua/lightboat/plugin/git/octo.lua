local M = {}
local util = require('lightboat.util')
local spec = {
  'pwntester/octo.nvim',
  enabled = vim.fn.executable('gh') == 1,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  opts = { picker = 'snacks' },
  event = { { event = 'User', pattern = 'NetworkChecked' } },
}

function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.git.octo', function() return spec end, M.clear)

return M
