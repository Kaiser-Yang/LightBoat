return {
  enabled = true,
  keys = {
    ['<f7>'] = { key = '<f7>', desc = 'Clear all highlighted words' },
    ['<f8>'] = { key = '<f8>', desc = 'Toggle highlight under cursor', mode = { 'n', 'x' }, expr = true },
    ['[w'] = { key = '[w', desc = 'Previous highlighted word', expr = true },
    [']w'] = { key = ']w', desc = 'Next highlighted word', expr = true },
  },
}
