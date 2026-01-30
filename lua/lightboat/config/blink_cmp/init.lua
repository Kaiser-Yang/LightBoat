return {
  enabled = true,
  ignored_keyword = {
    lua = { 'if', 'elseif', 'while', 'for', 'function', 'local' },
    go = { 'if', 'else', 'switch', 'case', 'func', 'var', 'const' },
  },
  keys = {
    ['<cr>'] = { key = '<cr>' },
    ['<c-j>'] = { key = '<c-j>' },
    ['<c-k>'] = { key = '<c-k>' },
    ['<c-s>'] = { key = '<c-s>' },
    ['<tab>'] = { key = '<tab>' },
    ['<s-tab>'] = { key = '<s-tab>' },
    ['<c-u>'] = { key = '<c-u>' },
    ['<c-d>'] = { key = '<c-d>' },
    ['<c-c>'] = { key = '<c-c>' },
  },
}
