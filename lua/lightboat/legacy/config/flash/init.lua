local big_file_check_wrap = require('lightboat.action').big_file_check_wrap
return {
  enabled = true,
  keys = {
    ['F'] = {
      key = 'F',
      prev = big_file_check_wrap('F'),
      expr = true,
      remap = true,
      mode = { 'n', 'x' },
      desc = 'Flash backwards find',
    },
    ['f'] = {
      key = 'f',
      prev = big_file_check_wrap('f'),
      expr = true,
      remap = true,
      mode = { 'n', 'x' },
      desc = 'Flash find',
    },
    ['T'] = {
      key = 'T',
      prev = big_file_check_wrap('T'),
      expr = true,
      remap = true,
      mode = { 'n', 'x' },
      desc = 'Flash backwards till',
    },
    ['t'] = {
      key = 't',
      prev = big_file_check_wrap('t'),
      expr = true,
      remap = true,
      mode = { 'n', 'x' },
      desc = 'Flash till',
    },
    ['r'] = { key = 'r', prev = 'big_file_check', mode = 'o', desc = 'Remote Flash' },
    ['R'] = { key = 'R', prev = 'big_file_check', mode = { 'o', 'x' }, desc = 'Treesitter Search' },
    ['gn'] = { key = 'gn', prev = 'big_file_check', mode = { 'n', 'x', 'o' }, desc = 'Flash Treesitter' },
    ['<c-s>'] = { key = '<c-s>', prev = 'big_file_check', mode = { 'n', 'x' }, desc = 'Flash Search Two Characters' },
  },
}
