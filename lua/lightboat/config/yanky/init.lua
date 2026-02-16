return {
  enabled = true,
  restore_anonymous_reg = true,
  keys = {
    ['y'] = {
      key = 'y',
      mode = { 'n', 'x', 'o' },
      expr = true,
      opts = { consider_wrap = false, consider_invisible = true, increase_count = true },
    },
    ['Y'] = {
      key = 'Y',
      expr = true,
      desc = 'Line wise yank',
      opts = { consider_wrap = false, consider_invisible = true, increase_count = true },
    },
    ['p'] = { key = 'p', mode = { 'n', 'x' } },
    ['P'] = { key = 'P', mode = { 'n', 'x' } },
    ['gp'] = { key = 'gp', mode = { 'n', 'x' } },
    ['gP'] = { key = 'gP', mode = { 'n', 'x' } },
    ['<m-c>'] = {
      key = '<m-c>',
      mode = { 'n', 'x', 'o' },
      expr = true,
      desc = 'Copy to + reg',
      opts = { consider_wrap = false, consider_invisible = true, increase_count = true },
    },
    ['<m-C>'] = {
      key = '<m-C>',
      expr = true,
      desc = 'Line wise copy to + reg',
      opts = { consider_wrap = false, consider_invisible = true, increase_count = true },

    },
    ['<m-v>'] = {
      key = '<m-v>',
      prev = 'try_to_paste_image_p',
      desc = 'Paste from clipboard (similar with "+p)',
      mode = { 'n', 'x', 'i', 'c', 'o' },
      expr = true,
    },
    ['<m-V>'] = {
      key = '<m-V>',
      prev = 'try_to_paste_image_P',
      desc = 'Paste from clipboard (similar with "+P)',
      mode = { 'n', 'x' },
      expr = true,
    },
    ['<c-rightmouse>'] = {
      key = '<c-rightmouse>',
      prev = 'try_to_paste_image_p_with_curl',
      expr = true,
      desc = 'Paste from + reg',
      mode = { 'n', 'x', 'i' },
    },
    ['gy'] = { key = 'gy', mode = { 'n', 'x' } },
  },
}
