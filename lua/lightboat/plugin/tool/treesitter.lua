return {
  'nvim-treesitter/nvim-treesitter',
  event = 'VeryLazy',
  cond = not vim.g.vscode,
  cmd = { 'TSUpdate', 'TSInstall', 'TSUninstall', 'TSInstallFromGrammar' },
  branch = 'main',
  build = ':TSUpdate',
  opts = {},
}
