vim.g.nvim_surround_no_mappings = true
return {
  {
    'saghen/blink.pairs',
    version = '*',
    cond = not vim.g.vscode,
    event = 'VeryLazy',
    dependencies = 'saghen/blink.download',
    opts = {
      mappings = {
        enabled = false,
        cmdline = false,
        disabled_filetypes = { 'TelescopePrompt' },
        pairs = {},
      },
      highlights = {
        enabled = true,
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
    lazy = true,
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
    lazy = true,
    opts = {
      tabkey = '',
      backwards_tabkey = '',
      act_as_tab = true,
      act_as_shift_tab = false,
      default_tab = '<tab>',
      default_shift_tab = '<s-tab>',
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
    opts = { move_cursor = 'sticky' },
  },
}
