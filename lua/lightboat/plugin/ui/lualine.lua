return {
  'nvim-lualine/lualine.nvim',
  dependencies = 'nvim-tree/nvim-web-devicons',
  lazy = false,
  cond = not vim.g.vscode,
  opts = {},
}
