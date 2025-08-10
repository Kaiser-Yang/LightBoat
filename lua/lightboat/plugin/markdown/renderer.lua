local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local M = {}

local function ts_context_render_or_clear(status)
  return function()
    local cur_win = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative == 'win' and cfg.row == 0 and cfg.win == cur_win and vim.w[win].treesitter_context then
        local buf = vim.api.nvim_win_get_buf(win)
        local new_ft = status and 'markdown' or ''
        if new_ft ~= vim.bo[buf].filetype then vim.bo[buf].filetype = new_ft end
        require('render-markdown.core.manager').set_buf(buf, status)
      end
    end
  end
end

local spec = {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    enabled = false,
    anti_conceal = { enabled = false },
    win_options = { concealcursor = { rendered = 'nvic' } },
    on = {
      attach = function()
        if vim.bo.filetype == 'Avante' then vim.cmd('RenderMarkdown buf_enable') end
      end,
      render = ts_context_render_or_clear(true),
      clear = ts_context_render_or_clear(false),
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
  spec.opts.file_types = c.markdown_fts
  return spec
end, M.clear)

return M
