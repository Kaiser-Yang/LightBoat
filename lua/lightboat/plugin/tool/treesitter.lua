return {
  'nvim-treesitter/nvim-treesitter',
  cond = not vim.g.vscode and vim.fn.executable('tar') == 1 and vim.fn.executable('curl') == 1 and vim.fn.executable(
    'tree-sitter'
  ) == 1,
  cmd = { 'TSUpdate', 'TSInstall', 'TSUninstall', 'TSInstallFromGrammar' },
  branch = 'main',
  build = ':TSUpdate',
  opts = {},
}
