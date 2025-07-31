local M = {}
local config = require('lightboat.config')
local c
local util = require('lightboat.util')
local key = util.key
local rep_move = require('lightboat.extra.rep_move')
local prev_hunk, next_hunk = rep_move.make(
  function() require('gitsigns').nav_hunk('prev') end,
  function() require('gitsigns').nav_hunk('next') end
)
local operation = {
  ['gcu'] = function() require('gitsigns').reset_hunk() end,
  ['gcd'] = function() require('gitsigns').preview_hunk() end,
  ['gcl'] = function() require('gitsigns').blame_line({ full = true }) end,
  ['[g'] = prev_hunk,
  [']g'] = next_hunk,
}
local spec = {
  'lewis6991/gitsigns.nvim',
  event = { { event = 'User', pattern = 'GitRepoDetected' } },
  opts = {
    current_line_blame = true,
    current_line_blame_opts = { delay = 300 },
    preview_config = { border = 'rounded' },
  },
  keys = {},
}

function M.spec() return spec end

M.clear = function()
  spec.keys = {}
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.git.sign', function()
  c = config.get().sign
  if not c.enabled then return nil end
  spec.keys = key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
