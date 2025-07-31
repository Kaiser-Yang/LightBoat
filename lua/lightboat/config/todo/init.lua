return {
  enabled = true,
  keys = {
    ['<leader>st'] = { key = '<leader>st', desc = 'Search todo comments' },
    [']t'] = { key = ']t', desc = 'Next todo comment', mode = { 'n', 'x', 'o' } },
    ['[t'] = { key = '[t', desc = 'Previous todo comment', mode = { 'n', 'x', 'o' } },
  },
}
