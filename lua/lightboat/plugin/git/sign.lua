return {
  'lewis6991/gitsigns.nvim',
  event = { { event = 'User', pattern = 'GitRepoDetected' } },
  cond = not vim.g.vscode,
  opts = {
    current_line_blame = true,
    current_line_blame_opts = { delay = 300 },
    preview_config = { border = vim.o.winborder or nil },
  },
}
