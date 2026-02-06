return {
  {
    'nvim-treesitter/nvim-treesitter',
    cond = not vim.g.vscode,
    -- This plugin can not be lazy loaded, make sure it is loaded during startup
    lazy = false,
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
