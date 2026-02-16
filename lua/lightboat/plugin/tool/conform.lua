return {
  'stevearc/conform.nvim',
  cond = not vim.g.vscode,
  opts = {
    notify_no_formatters = false,
    formatters_by_ft = { lua = { 'stylua' } },
    default_format_opts = { lsp_format = 'fallback', stop_after_first = true },
  },
  cmd = { 'ConformInfo' },
}
