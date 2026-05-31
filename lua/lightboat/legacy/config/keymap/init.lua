return {
  keys = {
    ['[z'] = { key = '[z', mode = { 'n', 'x' }, expr = true, desc = 'Move to start of current fold' },
    [']z'] = { key = ']z', mode = { 'n', 'x' }, expr = true, desc = 'Move to end of current fold' },
    ['zk'] = { key = 'zk', mode = { 'n', 'x' }, expr = true, desc = 'To the end of the previous fold' },
    ['zj'] = { key = 'zj', mode = { 'n', 'x' }, expr = true, desc = 'To the start of the next fold' },
  },
}
