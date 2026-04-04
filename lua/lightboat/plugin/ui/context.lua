return {
  'nvim-treesitter/nvim-treesitter-context',
  cond = not vim.g.vscode,
  event = 'VeryLazy',
  opts = {
    max_liens = vim.o.scrolloff,
    on_attach = function(buffer) return not require('lightboat.util').buffer.big(buffer) end,
  },
}
