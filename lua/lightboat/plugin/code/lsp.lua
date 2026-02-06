return {
  {
    'neovim/nvim-lspconfig',
    -- NOTE: Do not lazy load this plugin
    lazy = false,
    dependencies = { 'williamboman/mason.nvim' },
    cond = not vim.g.vscode,
    config = function()
      if vim.fn.executable('lua-language-server') ~= 0 then vim.lsp.enable('lua_ls') end
    end,
  },
}
