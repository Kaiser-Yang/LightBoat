return {
  'Kaiser-Yang/resolve.nvim',
  event = { { event = 'User', pattern = 'GitConflictDetected' } },
  cond = not vim.g.vscode,
  opts = {
    diff_view_labels = {
      ours = 'Current',
      theirs = 'Incoming',
      base = 'Base',
    },
    default_keymaps = false,
    on_conflict_detected = function(args) vim.diagnostic.enable(false, { bufnr = args.bufnr }) end,
    disable_diagnostics = function(args) vim.diagnostic.enable(true, { bufnr = args.bufnr }) end,
  },
}
