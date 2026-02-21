local M = {}
local util = require('lightboat.util')
local spec = {
  'sindrets/diffview.nvim', -- optional - Diff integration
  lazy = true,
  cmd = { 'DiffviewOpen' },
  keys = {
    {
      '<m-d>',
      function()
        for _, win in pairs(vim.api.nvim_tabpage_list_wins(0)) do
          local win_buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[win_buf].filetype == 'DiffviewFiles' then return '<cmd>DiffviewClose<cr>' end
        end
        return '<cmd>DiffviewOpen<cr>'
      end,
      desc = 'Open Diffview',
      expr = true,
    },
  },
}

function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.git.diffview', function() return spec end, M.clear)

return M
