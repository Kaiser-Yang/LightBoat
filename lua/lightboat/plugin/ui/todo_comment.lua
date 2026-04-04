-- TODO: maybe we do not need this one
return {
  'folke/todo-comments.nvim',
  cond = not vim.g.vscode,
  event = 'VeryLazy',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = { sign_priority = 1, highlight = { multiline = false } },
}
