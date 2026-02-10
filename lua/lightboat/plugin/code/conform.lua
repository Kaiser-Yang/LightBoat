return {
  'stevearc/conform.nvim',
  dependencies = { 'williamboman/mason.nvim' },
  cond = not vim.g.vscode,
  opts = {
    formatters_by_ft = {
      lua = { 'stylua' },
      c = { 'clang-format' },
      cpp = { 'clang-format' },
      go = { 'goimports' },
      python = { 'black' },
      bash = { 'shellharden' },
    },
    default_format_opts = { lsp_format = 'fallback', stop_after_first = true },
  },
  cmd = { 'ConformInfo' },
}
