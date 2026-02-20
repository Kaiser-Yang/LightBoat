return {
  enabled = true,
  rainbow_limit_lines = 5000,
  keys = {
    ['g%'] = { key = 'g%', expr = true, mode = { 'n', 'x' }, desc = 'Previous matchup' },
    ['%'] = { key = '%', expr = true, mode = { 'n', 'x' }, desc = 'Next matchup' },
    ['[%'] = { key = '[%', expr = true, mode = { 'n', 'x' }, desc = 'Previous multi matchup' },
    [']%'] = { key = ']%', mode = { 'n', 'x' }, expr = true, desc = 'Next multi matchup' },
    ['Z%'] = { key = 'Z%', expr = true, mode = { 'n', 'x' }, desc = 'Previous start of inner matchup' },
    ['z%'] = { key = 'z%', expr = true, mode = { 'n', 'x' }, desc = 'Next start of inner matchup' },
  },
}
