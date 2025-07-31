local M = {}
local util = require('lightboat.util')
local spec = {
  'catppuccin/nvim',
  name = 'catppuccin',
  lazy = false,
  priority = 1000,
  opts = { flavour = 'mocha', integrations = { blink_cmp = false } },
  config = function(_, opts)
    require('catppuccin').setup(_, opts)
    vim.cmd('colorscheme catppuccin')
  end,
}
function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.ui.catppuccin', function() return spec end, M.clear)

return M
