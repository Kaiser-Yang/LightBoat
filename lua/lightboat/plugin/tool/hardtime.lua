return {
  'm4xshen/hardtime.nvim',
  dependencies = 'MunifTanjim/nui.nvim',
  opts = {
    disable_mouse = false,
    restriction_mode = 'hint',
    disabled_keys = {
      ['<Up>'] = { 'n', 'x' },
      ['<Down>'] = { 'n', 'x' },
      ['<Left>'] = { 'n', 'x' },
      ['<Right>'] = { 'n', 'x' },
    },
    hints = {
      ['dl'] = { message = function() return 'Use x instead of dl' end, length = 2 },
      ['cl'] = { message = function() return 'Use s instead of cl' end, length = 2 },
      ['%^C'] = { message = function() return 'Use S or cc instead of ^C' end, length = 2 },
    },
  },
}
