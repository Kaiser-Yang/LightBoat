local big_file = require('lightboat.extra.big_file')
local util = require('lightboat.util')
local M = {}

local spec = {
  'brenoprata10/nvim-highlight-colors',
  cmd = 'HighlightColors',
  cond = not vim.g.vscode,
  event = { { event = 'User', pattern = 'ColorDetected' } },
  lazy = vim.fn.executable('rg') == 1,
  opts = {
    -- PERF: disabled in large files
    exclude_buffer = big_file.is_big_file,
  },
  ft = { 'css', 'scss', 'less', 'html', 'javascript', 'typescript', 'vue', 'svelte', 'astro' },
}

function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.extra.color', function() return spec end, M.clear)

return M
