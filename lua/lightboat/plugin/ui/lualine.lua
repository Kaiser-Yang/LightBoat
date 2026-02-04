return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = 'nvim-tree/nvim-web-devicons',
    cond = not vim.g.vscode,
    opts = {},
  },
}
