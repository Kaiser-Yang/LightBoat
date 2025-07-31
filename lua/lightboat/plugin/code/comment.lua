local util = require('lightboat.util')
local map = util.key.set
local del = util.key.del
local config = require('lightboat.config')
local c
local line_wise_key_wrap = require('lightboat.extra.line_wise').line_wise_key_wrap

local M = {}

local function kmp_prefix(word)
  local n = #word
  local prefix = { 0 }
  local k = 0
  for i = 2, n do
    while k > 0 and word:sub(k + 1, k + 1) ~= word:sub(i, i) do
      k = prefix[k]
    end
    if word:sub(k + 1, k + 1) == word:sub(i, i) then k = k + 1 end
    prefix[i] = k
  end
  return prefix
end

local function kmp_search(text, word)
  if #word == 0 then return 1 end
  local prefix = kmp_prefix(word)
  local j = 0
  for i = 1, #text do
    while j > 0 and word:sub(j + 1, j + 1) ~= text:sub(i, i) do
      j = prefix[j]
    end
    if word:sub(j + 1, j + 1) == text:sub(i, i) then j = j + 1 end
    if j == #word then return i - #word + 1 end
  end
  return -1
end

function M.toggle_comment_insert_mode(key)
  local before_line = vim.api.nvim_get_current_line()
  local _, before_col = unpack(vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win()))
  local at_end = before_col == #before_line
  if before_line:match('^%s*$') then return end
  vim.schedule(function()
    local current_line = vim.api.nvim_get_current_line()
    local delta = #current_line - #before_line
    local first_neq_col
    local min_len = math.min(#current_line, #before_line)
    for i = 1, min_len do
      if current_line:sub(i, i) ~= before_line:sub(i, i) then
        first_neq_col = i
        break
      end
    end
    local left_delta = kmp_search(
      delta > 0 and current_line:sub(first_neq_col) or before_line:sub(first_neq_col),
      delta < 0 and current_line:sub(first_neq_col) or before_line:sub(first_neq_col)
    ) - 1
    local row, col = unpack(vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win()))
    if delta > 0 then
      if col < first_neq_col - 1 then return end
      col = col + left_delta
      if at_end then col = col + 1 end
    else
      if col < first_neq_col - 1 then
        return
      elseif col < first_neq_col + left_delta - 1 then
        col = col - (math.abs(left_delta - (first_neq_col + left_delta - 1 - col)))
      else
        col = col - (left_delta - math.abs(col - before_col))
      end
    end
    vim.api.nvim_win_set_cursor(0, { row, col })
  end)
  return '<c-o>' .. key
end

local operation = {
  ['<leader>A'] = function() require('Comment.api').locked('insert.linewise.eol')() end,
  ['<leader>O'] = function() require('Comment.api').insert.linewise.above() end,
  ['<leader>o'] = function() require('Comment.api').insert.linewise.below() end,
  ['<leader>c'] = '<plug>(comment_toggle_linewise)',
  ['<leader>C'] = '<Plug>(comment_toggle_blockwise)',
  ['<m-/>'] = function()
    if vim.fn.mode() == 'i' then return M.toggle_comment_insert_mode('<f37>') end
    return vim.fn.mode() == 'n' and line_wise_key_wrap('<f37>')() or '<Plug>(comment_toggle_linewise_visual)'
  end,
  ['<m-?>'] = function()
    if vim.fn.mode() == 'i' then return M.toggle_comment_insert_mode('<f38>') end
    return vim.fn.mode() == 'n' and line_wise_key_wrap('<f38>')() or '<Plug>(comment_toggle_blockwise_visual)'
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
