return {
  'nvim-lualine/lualine.nvim',
  dependencies = 'nvim-tree/nvim-web-devicons',
  lazy = false,
  cond = not vim.g.vscode,
  opts = {
    options = {
      always_divide_middle = true,
      disabled_filetypes = { statusline = { 'NvimTree' } },
    },
    extensions = { 'quickfix' },
  },
}
