local util = require('lightboat.util')
local map = util.key.set
local del = util.key.del
local config = require('lightboat.config')
local c
local line_wise_key_wrap = require('lightboat.extra.line_wise').line_wise_key_wrap

local M = {}

local operation = {
  ['<leader>A'] = function() require('Comment.api').locked('insert.linewise.eol')() end,
  ['<leader>O'] = function() require('Comment.api').insert.linewise.above() end,
  ['<leader>o'] = function() require('Comment.api').insert.linewise.below() end,
  ['<leader>c'] = '<plug>(comment_toggle_linewise)',
  ['<leader>C'] = '<Plug>(comment_toggle_blockwise)',
  ['<m-/>'] = function()
    if vim.fn.mode('1') == 'i' then return M.toggle_comment_insert_mode('<f37>') end
    return vim.fn.mode('1') == 'n' and line_wise_key_wrap('<f37>')() or '<Plug>(comment_toggle_linewise_visual)'
  end,
  ['<m-?>'] = function()
    if vim.fn.mode('1') == 'i' then return M.toggle_comment_insert_mode('<f38>') end
    return vim.fn.mode('1') == 'n' and line_wise_key_wrap('<f38>')() or '<Plug>(comment_toggle_blockwise_visual)'
  end,
}

local spec = {
  'numToStr/Comment.nvim',
  dependencies = { { 'JoosepAlviste/nvim-ts-context-commentstring', opts = { enable_autocmd = false } } },
  opts = {
    ignore = '^%s*$',
    mappings = false,
    pre_hook = function() require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook() end,
  },
  keys = {},
}

function M.clear()
  spec.keys = {}
  del('n', '<f37>')
  del('n', '<f38>')
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.code.comment', function()
  c = config.get().comment
  if not c.enabled then return nil end
  map('n', '<f37>', function()
    if vim.v.count == 0 then
      return '<plug>(comment_toggle_linewise_current)'
    else
      return '<plug>(comment_toggle_linewise_count)'
    end
  end, { expr = true, desc = 'This key is a indirect key for line wise comment' })
  map('n', '<f38>', function()
    if vim.v.count == 0 then
      return '<Plug>(comment_toggle_blockwise_current)'
    else
      return '<Plug>(comment_toggle_blockwise_count)'
    end
  end, { expr = true, desc = 'This key is a indirect key for line wise block comment' })
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
