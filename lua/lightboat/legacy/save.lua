local util = require('lightboat.util')
local spec = {
  'Pocco81/auto-save.nvim',
  cond = not vim.g.vscode,
  event = 'VeryLazy',
  opts = {
    execution_message = { message = '' },
    -- Save a large file may take seconds
    condition = function(buf)
      if not vim.api.nvim_buf_is_valid(buf) then return false end
      return not require('lightboat.extra.big_file').is_big_file(buf)
    end,
  },
}
local M = {}

function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.save', function() return spec end, M.clear)

return M
