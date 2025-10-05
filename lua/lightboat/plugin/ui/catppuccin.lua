local M = {}
local util = require('lightboat.util')
local spec = {
  'catppuccin/nvim',
  name = 'catppuccin',
  cond = not vim.g.vscode,
  opts = {
    flavour = 'mocha',
    integrations = {
      dap = false,
      flash = true,
      mason = true,
      noice = true,
      notify = true,
      nvim_surround = true,
      octo = true,
      overseer = true,
      rainbow_delimiters = false,
      which_key = true,
      window_picker = true,
    },
  },
  config = function(_, opts)
    require('catppuccin').setup(opts)
    vim.cmd('colorscheme catppuccin')
  end,
}
function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.ui.catppuccin', function() return spec end, M.clear)

return M
