local M = {}
local config = require('lightboat.config')
local c
local util = require('lightboat.util')
local key = util.key
local rep_move = require('lightboat.extra.rep_move')
local prev_conflict, next_conflict =
  rep_move.make('<plug>(git-conflict-prev-conflict)', '<plug>(git-conflict-next-conflict)')
local operation = {
  ['gcc'] = '<plug>(git-conflict-ours)',
  ['gci'] = '<plug>(git-conflict-theirs)',
  ['gcb'] = '<plug>(git-conflict-both)',
  ['gcn'] = '<plug>(git-conflict-none)',
  [']x'] = next_conflict,
  ['[x'] = prev_conflict,
}
local spec = {
  'akinsho/git-conflict.nvim',
  version = '*',
  event = { { event = 'User', pattern = 'GitRepoDetected' } },
  opts = {
    default_mappings = false,
    disable_diagnostics = true,
  },
  keys = {},
}
function M.spec() return spec end

function M.clear()
  spec.keys = {}
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.git.conflict', function()
  c = config.get().conflict
  if not c.enabled then return nil end
  spec.keys = key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
