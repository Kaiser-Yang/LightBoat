return {
  'spacedentist/resolve.nvim',
  cond = not vim.g.vscode,
  opts = {
    default_keymaps = false,
    on_conflict_detected = function(args) vim.diagnostic.enable(false, { bufnr = args.bufnr }) end,
    disable_diagnostics = function(args) vim.diagnostic.enable(true, { bufnr = args.bufnr }) end,
  },
}
