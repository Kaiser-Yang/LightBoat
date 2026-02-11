return {
  'saghen/blink.indent',
  opts = {
    mappings = {
      object_scope = '<plug>(inside-indent)',
      object_scope_with_border = '<plug>(around-indent)',
      goto_top = '<plug>(goto-indent-top)',
      goto_bottom = '<plug>(goto-indent-bottom)',
    },
    static = {
      char = '│',
    },
    scope = {
      enabled = true,
      char = '│',
      priority = 1000,
      highlights = {
        'BlinkIndentViolet',
        'BlinkIndentCyan',
        'BlinkIndentBlue',
        'BlinkIndentGreen',
        'BlinkIndentYellow',
        'BlinkIndentOrange',
        'BlinkIndentRed',
      },
      underline = {
        enabled = true,
        highlights = {
          'BlinkIndentVioletUnderline',
          'BlinkIndentCyanUnderline',
          'BlinkIndentBlueUnderline',
          'BlinkIndentGreenUnderline',
          'BlinkIndentYellowUnderline',
          'BlinkIndentOrangeUnderline',
          'BlinkIndentRedUnderline',
        },
      },
    },
  },
}
