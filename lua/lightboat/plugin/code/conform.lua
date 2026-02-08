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
  init = function()
    -- NOTE:
    -- make sure use conform instead of lsp for formatexpr
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('ConformLspAttach', { clear = true }),
      callback = function() vim.bo.formatexpr = "v:lua.require'conform'.formatexpr()" end,
    })
  end,
  cmd = { 'ConformInfo' },
}
