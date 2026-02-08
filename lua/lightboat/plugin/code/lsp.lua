return {
  'neovim/nvim-lspconfig',
  event = 'VeryLazy',
  cond = not vim.g.vscode,
  config = false,
}
