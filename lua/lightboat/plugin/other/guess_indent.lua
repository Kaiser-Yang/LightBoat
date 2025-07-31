local util = require('lightboat.util')
local spec = {
  'NMAC427/guess-indent.nvim',
  event = 'VeryLazy',
  opts = {
    filetype_exclude = {
      'netrw',
      'tutor',
      'neo-tree',
      'Avante',
      'AvanteInput',
    },
    buftype_exclude = {
      'help',
      'nofile',
      'terminal',
      'prompt',
    },
    on_tab_options = {
      expandtab = false,
      tabstop = 4,
      shiftwidth = 4,
    },
  },
}

local M = {}

function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.guess_indent', function() return spec end, M.clear)

return M
