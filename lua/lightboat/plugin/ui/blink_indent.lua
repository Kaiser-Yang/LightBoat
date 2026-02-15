return {
  'saghen/blink.indent',
  lazy = false,
  opts = {
    mappings = {
      object_scope = '<plug>(blink-indent-inside)',
      object_scope_with_border = '<plug>(blink-indent-around)',
      goto_top = '<plug>(blink-indent-top)',
      goto_bottom = '<plug>(blink-indent-bottom)',
    },
    static = {
      whitespace_char = '·',
      char = '│',
    },
    scope = {
      enabled = true,
      char = '│',
      priority = 1000,
      highlights = {
        'BlinkIndentRed',
        'BlinkIndentOrange',
        'BlinkIndentYellow',
        'BlinkIndentGreen',
        'BlinkIndentBlue',
        'BlinkIndentCyan',
        'BlinkIndentViolet',
      },
      underline = {
        enabled = true,
        highlights = {
          'BlinkIndentRedUnderline',
          'BlinkIndentOrangeUnderline',
          'BlinkIndentYellowUnderline',
          'BlinkIndentGreenUnderline',
          'BlinkIndentBlueUnderline',
          'BlinkIndentCyanUnderline',
          'BlinkIndentVioletUnderline',
        },
      },
    },
  },
}
