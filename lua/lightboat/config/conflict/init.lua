return {
  enabled = true,
  keys = {
    ['gca'] = { key = 'gca', desc = 'Git keep ancestor' },
    ['gcb'] = { key = 'gcb', desc = 'Git keep both' },
    ['gcc'] = { key = 'gcc', desc = 'Git keep current' },
    ['gci'] = { key = 'gci', desc = 'Git keep incomming' },
    ['gcn'] = { key = 'gcn', desc = 'Git keep none' },
    [']x'] = { key = ']x', desc = 'Next git conflict', expr = true, mode = { 'n', 'x', 'o' } },
    ['[x'] = { key = '[x', desc = 'Prev git conflict', expr = true, mode = { 'n', 'x', 'o' } },
  },
}
