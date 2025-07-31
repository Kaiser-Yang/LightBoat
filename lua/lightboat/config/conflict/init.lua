return {
  enabled = true,
  keys = {
    ['gcc'] = { key = 'gcc', desc = 'Git keep current' },
    ['gci'] = { key = 'gci', desc = 'Git keep incomming' },
    ['gcb'] = { key = 'gcb', desc = 'Git keep both' },
    ['gcn'] = { key = 'gcn', desc = 'Git keep none' },
    [']x'] = { key = ']x', desc = 'Next git conflict', mode = { 'n', 'x', 'o' } },
    ['[x'] = { key = '[x', desc = 'Prev git conflict', mode = { 'n', 'x', 'o' } },
  },
}
