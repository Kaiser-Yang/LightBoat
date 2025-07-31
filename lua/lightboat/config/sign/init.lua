return {
  enabled = true,
  keys = {
    ['gcu'] = { key = 'gcu', desc = 'Git reset current hunk' },
    ['gcd'] = { key = 'gcd', desc = 'Git diff current hunk' },
    ['gcl'] = { key = 'gcl', desc = 'Git blame current line' },
    ['[g'] = { key = '[g', desc = 'Previous git hunk', mode = { 'n', 'x', 'o' } },
    [']g'] = { key = ']g', desc = 'Next git hunk', mode = { 'n', 'x', 'o' } },
  },
}
