return {
  {
    'nvim-treesitter/nvim-treesitter',
    cond = not vim.g.vscode,
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
    event = 'VeryLazy',
    cond = not vim.g.vscode,
    opts = {},
  },
}
