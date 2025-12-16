local M = {}
local util = require('lightboat.util')
local spec = {
  'NeogitOrg/neogit',
  lazy = true,
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    {
      'sindrets/diffview.nvim', -- optional - Diff integration
      lazy = true,
      cmd = { 'DiffviewOpen' },
      keys = { { '<m-d>', '<cmd>DiffviewOpen<cr>', desc = 'Open Diffview' } },
    },
  },
  cmd = 'Neogit',
  opts = {
    mappings = {
      status = {
        ['Q'] = 'Close',
      },
    },
  },
  keys = {
    { '<m-g>', '<cmd>Neogit<cr>', desc = 'Show Neogit UI' },
  },
}

function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.git.neogit', function() return spec end, M.clear)

return M
