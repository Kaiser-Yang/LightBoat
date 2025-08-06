local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local M = {}

local spec = {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    enabled = false,
    file_types = vim.g.markdown_support_filetype,
    anti_conceal = { enabled = false },
    win_options = { concealcursor = { rendered = 'nvic' } },
    on = {
      attach = function()
        if vim.bo.filetype == 'Avante' then vim.cmd('RenderMarkdown buf_enable') end
      end,
    },
  },
}

function M.clear()
  spec.ft = nil
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.other.markdown', function()
  c = config.get().extra
  spec.ft = c.markdown_fts
  return spec
end, M.clear)

return M
