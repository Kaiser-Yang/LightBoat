return {
  {
    'saghen/blink.pairs',
    version = '*',
    cond = not vim.g.vscode,
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = 'saghen/blink.download',
    opts = {
      mappings = {
        enabled = false,
        cmdline = false,
        disabled_filetypes = {},
        pairs = {},
      },
      highlights = {
        -- PERF:
        -- https://github.com/saghen/blink.pairs/issues/72
        enabled = false,
        cmdline = pcall(require, 'vim._extui'),
        groups = {
          'BlinkPairsRed',
          'BlinkPairsOrange',
          'BlinkPairsYellow',
          'BlinkPairsGreen',
          'BlinkPairsBlue',
          'BlinkPairsCyan',
          'BlinkPairsPurple',
        },
        unmatched_group = 'BlinkPairsUnmatched',
        matchparen = {
          enabled = true,
          cmdline = pcall(require, 'vim._extui'),
          include_surrounding = false,
          group = 'BlinkPairsMatchParen',
          priority = 250,
        },
      },
    },
  },
  {
    -- PERF:
    'altermo/ultimate-autopair.nvim',
    cond = not vim.g.vscode,
    event = { 'InsertEnter', 'CmdlineEnter' },
    branch = 'v0.6',
    opts = {
      tabout = { enable = true, hopout = true },
      fastwarp = { nocursormove = false },
    },
    config = function(_, opts)
      -- HACK:
      -- Find a better way to do this, we should not use the config function
      -- because users may use it too, which will make our config function not be called
      -- Do not map by default
      require('ultimate-autopair.core').modes = {}
      require('ultimate-autopair').setup(opts)
    end,
  },
  {
    'abecodes/tabout.nvim',
    event = { 'InsertEnter', 'CmdlineEnter' },
    opts = {
      tabkey = '<plug>(tabout)',
      backwards_tabkey = '<plug>(reverse-tabout)',
      act_as_tab = true,
      act_as_shift_tab = false,
      default_tab = '<C-t>', -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
      default_shift_tab = '<C-d>', -- reverse shift default action,
      enable_backwards = true,
      completion = true,
      tabouts = {
        { open = "'", close = "'" },
        { open = '"', close = '"' },
        { open = '`', close = '`' },
        { open = '(', close = ')' },
        { open = '[', close = ']' },
        { open = '{', close = '}' },
      },
      ignore_beginning = true,
    },
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
}
