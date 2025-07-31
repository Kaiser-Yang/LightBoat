return {
  enabled = true,
  keys = {
    ['<leader>A'] = { key = '<leader>A', desc = 'Comment insert end of line' },
    ['<leader>O'] = { key = '<leader>O', desc = 'Comment insert above' },
    ['<leader>o'] = { key = '<leader>o', desc = 'Comment insert below' },
    ['<leader>c'] = { key = '<leader>c', desc = 'Comment toggle linewise' },
    ['<leader>C'] = { key = '<leader>C', desc = 'Comment toggle blockwise' },
    ['<m-/>'] = {
      key = '<m-/>',
      mode = { 'n', 'x', 'i' },
      expr = true,
      remap = true,
      desc = 'Toggle comment for current line',
    },
    ['<m-?>'] = {
      key = '<m-?>',
      mode = { 'n', 'x', 'i' },
      expr = true,
      remap = true,
      desc = 'Comment toggle current block',
    },
  },
}
