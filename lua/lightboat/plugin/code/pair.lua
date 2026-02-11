return {
  {
    'altermo/ultimate-autopair.nvim',
    cond = not vim.g.vscode,
    lazy = true,
    branch = 'v0.6',
    opts = {
      bs = { space = 'balance', indent_ignore = true, delete_from_end = false },
      cr = { autoclose = true },
      tabout = { enable = true, hopout = true },
      space2 = { enable = true },
      fastwarp = { faster = true, nocursormove = false },
      config_internal_pairs = {
        { '[', ']', dosuround = false },
        { '(', ')', dosuround = false },
        { '{', '}', dosuround = false },
      },
    },
    config = function(_, opts)
      -- NOTE:
      -- Do not map by default
      -- HACK:
      -- Find a better way to do this, we should not use the config function
      -- because users may use it too, which will make our config function not be called
      require('ultimate-autopair.core').modes = {}
      require('ultimate-autopair').setup(opts)
    end,
  },
  {
    'kylechui/nvim-surround',
    version = '*',
    lazy = true,
    opts = {
      move_cursor = 'sticky',
      keymaps = {
        insert = false,
        insert_line = false,
        normal = false,
        normal_cur = false,
        normal_line = false,
        normal_cur_line = false,
        visual = false,
        visual_line = false,
        delete = false,
        change = false,
        change_line = false,
      },
    },
  },
  { 'RRethy/nvim-treesitter-endwise', event = 'InsertEnter' },
}
