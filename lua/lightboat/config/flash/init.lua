return {
  enabled = true,
  keys = {
    ['F'] = { key = 'F', expr = true, remap = true, mode = { 'n', 'x' }, desc = 'Flash backwards find' },
    ['f'] = { key = 'f', expr = true, remap = true, mode = { 'n', 'x' }, desc = 'Flash find' },
    ['T'] = { key = 'T', expr = true, remap = true, mode = { 'n', 'x' }, desc = 'Flash backwards till' },
    ['t'] = { key = 't', expr = true, remap = true, mode = { 'n', 'x' }, desc = 'Flash till' },
    ['<c-s>'] = { key = '<c-s>', mode = { 'n', 'x' }, desc = 'Flash Search Two Characters' },
    ['r'] = { key = 'r', mode = 'o', desc = 'Remote Flash' },
    ['R'] = { key = 'R', mode = { 'o', 'x' }, desc = 'Treesitter Search' },
    ['gn'] = { key = 'gn', mode = { 'n', 'x', 'o' }, desc = 'Flash Treesitter' },
  },
}
