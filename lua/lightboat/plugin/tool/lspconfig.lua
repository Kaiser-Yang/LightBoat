return {
  'neovim/nvim-lspconfig',
  cond = not vim.g.vscode,
  cmd = { 'LspInfo', 'LspStart', 'LspStop', 'LspRestart' },
  lazy = true,
  config = false,
}
