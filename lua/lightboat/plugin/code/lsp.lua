return {
  {
    'neovim/nvim-lspconfig',
    -- NOTE:
    -- Do not lazy load this plugin
    lazy = false,
    -- NOTE:
    -- We add mason here to make sure mason set paths of LSPs
    dependencies = { 'williamboman/mason.nvim' },
    cond = not vim.g.vscode,
    config = function()
      if vim.fn.executable('lua-language-server') ~= 0 then vim.lsp.enable('lua_ls') end
    end,
  },
}
