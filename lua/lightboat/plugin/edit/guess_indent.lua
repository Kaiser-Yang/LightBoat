return {
  'NMAC427/guess-indent.nvim',
  event = 'BufRead',
  cmd = 'GuessIndent',
  opts = { on_tab_options = { shiftwidth = 0, expandtab = false, softtabstop = 0 } },
}
