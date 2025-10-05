local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local operation = {
  ['<leader>?'] = function() require('which-key').show() end,
  ['s'] = '<cmd>WhichKey n s<cr>',
}
local spec = {
  'folke/which-key.nvim',
  cond = not vim.g.vscode,
  event = 'VeryLazy',
  opts = {
    delay = vim.o.timeoutlen,
    sort = { 'alphanum', 'local', 'order', 'group', 'mod' },
    -- PERF:
    -- When enabling the registers plugin,
    -- it will cause a performance problem when the content is large.
    plugins = { spelling = { enabled = false }, registers = true },
  },
  keys = {},
}

local M = {}

function M.spec() return spec end

function M.clear() spec.keys = {} end

M.setup = util.setup_check_wrap('lightboat.plugin.which_key', function()
  c = config.get().which_key
  spec.enabled = c.enabled
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
