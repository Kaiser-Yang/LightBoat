return {
  'folke/todo-comments.nvim',
  cond = not vim.g.vscode,
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    sign_priority = 1,
    highlight = { multiline = false },
    search = {
      command = 'rg',
      args = {
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
      },
      pattern = [[\b(KEYWORDS):]],
    },
  },
}
