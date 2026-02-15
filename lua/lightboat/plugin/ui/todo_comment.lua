return {
  'folke/todo-comments.nvim',
  cond = not vim.g.vscode,
  lazy = false,
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = { sign_priority = 1, highlight = { multiline = false } },
}
