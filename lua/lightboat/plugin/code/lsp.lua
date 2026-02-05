return {
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'saghen/blink.cmp', 'williamboman/mason.nvim' },
    cond = not vim.g.vscode,
    config = function()
      if vim.fn.executable('lua-language-server') ~= 0 then vim.lsp.enable('lua_ls') end
    end,
  },
}
