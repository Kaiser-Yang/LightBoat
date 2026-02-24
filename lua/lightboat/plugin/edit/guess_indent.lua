return {
  'NMAC427/guess-indent.nvim',
  event = 'BufReadPre',
  cmd = 'GuessIndent',
  opts = { on_tab_options = { shiftwidth = 0 } },
}
