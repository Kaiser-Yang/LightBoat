return {
  'Kaiser-Yang/resolve.nvim',
  event = { { event = 'User', pattern = 'GitConflictDetected' } },
  cond = not vim.g.vscode,
  opts = {
    default_keymaps = false,
    auto_detect_enabled = false,
  },
}
