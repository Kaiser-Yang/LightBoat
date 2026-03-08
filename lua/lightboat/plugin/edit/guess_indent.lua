return {
  'NMAC427/guess-indent.nvim',
  event = 'BufRead',
  cmd = 'GuessIndent',
  opts = { on_tab_options = { shiftwidth = 0, softtabstop = 0, tabstop = 8 } },
}
