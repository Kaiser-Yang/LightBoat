return {
  'folke/todo-comments.nvim',
  cond = not vim.g.vscode,
  -- INFO: lazy loading here is OK, since todo-comments.nvim will not draw the buffer at startup
  event = 'VeryLazy',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = { sign_priority = 1, highlight = { multiline = false } },
}
