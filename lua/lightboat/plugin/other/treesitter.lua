return {
  {
    'nvim-treesitter/nvim-treesitter',
    cond = not vim.g.vscode,
    cmd = { 'TSUpdate', 'TSInstall', 'TSUninstall', 'TSInstallFromGrammar' },
    event = 'VeryLazy',
    branch = 'main',
    build = ':TSUpdate',
    opts = {},
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    lazy = true,
    branch = 'main',
    opts = {},
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    cond = not vim.g.vscode,
    opts = {},
  },
}
