return {
  enabled = true,
  enable_spell_check = true,
  max_search_lines = 10,
  keys = {
    ['o'] = { key = 'o', mode = 'n', buffer = true, remap = true },
    ['<cr>'] = { key = '<cr>', mode = 'i', buffer = true },
    ['<bs>'] = { key = '<bs>', mode = 'i', buffer = true },
    ['<tab>'] = { key = '<tab>', mode = 'i', buffer = true },
    ['gx'] = { key = 'gx', mode = { 'n', 'x' }, buffer = true, desc = 'Toggler check boxes' },
  },
}
