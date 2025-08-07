return {
  enabled = true,
  keys = {
    ['y'] = { key = 'y', mode = { 'n', 'x' } },
    ['p'] = { key = 'p', mode = { 'n', 'x' } },
    ['gp'] = { key = 'gp', mode = { 'n', 'x' } },
    ['gP'] = { key = 'gP', mode = { 'n', 'x' } },
    ['P'] = { key = 'P', mode = { 'n', 'x' } },
    ['Y'] = { key = 'Y', expr = true, desc = 'Line wise yank' },
    ['<leader>Y'] = { key = '<leader>Y', expr = true, desc = 'Line wise yank to + reg' },
    ['<leader>y'] = { key = '<leader>y', expr = true, desc = 'Yank to + reg', mode = { 'n', 'x' } },
    ['<m-c>'] = { key = '<m-c>', mode = { 'n', 'x' }, expr = true, desc = 'Copy to + reg' },
    ['<c-rightmouse>'] = { key = '<c-rightmouse>', expr = true, desc = 'Paste from + reg', mode = { 'n', 'x', 'i' } },
    ['<m-v>'] = { key = '<m-v>', desc = 'Paste from + reg', mode = { 'n', 'x', 'i', 'c' }, expr = true },
    ['<leader>p'] = { key = '<leader>p', expr = true, desc = 'Paste from clipboard', mode = { 'n', 'x' } },
    ['<leader>P'] = { key = '<leader>P', expr = true, desc = 'Paste from clipboard', mode = { 'n', 'x' } },
    ['gy'] = { key = 'gy', mode = { 'n', 'x' } },
  },
}
