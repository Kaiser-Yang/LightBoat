vim.g.interestingWordsDefaultMappings = 0
local util = require('lightboat.util')
local rep_move = require('lightboat.extra.rep_move')
local config = require('lightboat.config')
local c
local prev_highlight_word, next_highlight_word =
  rep_move.make('<cmd>call WordNavigation(0)<cr>', '<cmd>call WordNavigation(1)<cr>')
local operation = {
  ['<f7>'] = '<cmd>call UncolorAllWords()<cr>',
  ['<f8>'] = function()
    if vim.fn.mode('1') == 'n' then
      return "<cmd>call InterestingWords('n')<cr>"
    else
      return "<cmd>call InterestingWords('v')<cr>"
    end
  end,
  ['[w'] = prev_highlight_word,
  [']w'] = next_highlight_word,
}
local spec = {
  'lfv89/vim-interestingwords',
  cond = not vim.g.vscode,
  keys = {},
}
local M = {}

function M.clear()
  spec.keys = {}
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.edit.interesting_words', function()
  if vim.g.vscode then return spec end
  c = config.get().interesting_words
  spec.enabled = c.enabled
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
