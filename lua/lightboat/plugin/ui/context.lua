return {
  'nvim-treesitter/nvim-treesitter-context',
  cond = not vim.g.vscode,
  lazy = false,
  opts = { on_attach = function(buffer) return not require('lightboat.util').buffer.big(buffer) end },
}
