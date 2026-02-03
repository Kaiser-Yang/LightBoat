return {
  {
    'nvim-treesitter/nvim-treesitter',
    cond = not vim.g.vscode,
    branch = 'main',
    build = ':TSUpdate',
    opts = {},
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    -- INFO:
    -- Disable entire built-in ftplugin mappings to avoid conflicts.
    -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
    init = function() vim.g.no_plugin_maps = true end,
    branch = 'main',
    opts = {},
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    cond = not vim.g.vscode,
    opts = {},
  },
}
