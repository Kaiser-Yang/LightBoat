return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = 'nvim-tree/nvim-web-devicons',
    event = 'VeryLazy',
    cond = not vim.g.vscode,
    opts = {},
  },
}
