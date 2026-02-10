return {
  'numToStr/Comment.nvim',
  lazy = true,
  dependencies = { { 'JoosepAlviste/nvim-ts-context-commentstring', opts = { enable_autocmd = false } } },
  opts = {
    ignore = '^%s*$',
    mappings = false,
    pre_hook = function() require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook() end,
  },
}
