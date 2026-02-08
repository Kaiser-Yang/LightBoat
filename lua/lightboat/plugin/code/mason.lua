return {
  'williamboman/mason.nvim',
  event = 'VeryLazy',
  cond = not vim.g.vscode,
  opts = {},
}
