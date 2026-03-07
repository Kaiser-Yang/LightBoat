return {
  'nvim-lualine/lualine.nvim',
  dependencies = 'nvim-tree/nvim-web-devicons',
  lazy = false,
  cond = not vim.g.vscode,
  opts = { options = { globalstatus = true, always_divide_middle = true } },
}
