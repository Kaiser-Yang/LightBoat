return {
  enabled = true,
  surround = {
    keys = {
      ['ys'] = { key = 'ys', desc = 'Add a surrounding pair around a motion (normal mode)' },
      ['yS'] = { key = 'yS', desc = 'Add a surrounding pair around the current line (normal mode)' },
      ['S'] = { key = 'S', desc = 'Add a surrounding pair around a visual selection', mode = 'x' },
      ['ds'] = { key = 'ds', desc = 'Delete a surrounding pair' },
      ['cs'] = { key = 'cs', desc = 'Change a surrounding pair' },
    },
  },
  matchup = {
    keys = {
      ['g%'] = { key = 'g%', expr = true, mode = { 'n', 'x' }, desc = 'Previous matchup' },
      ['%'] = { key = '%', expr = true, mode = { 'n', 'x' }, desc = 'Next matchup' },
      ['[%'] = { key = '[%', expr = true, mode = { 'n', 'x' }, desc = 'Previous multi matchup' },
      [']%'] = { key = ']%', mode = { 'n', 'x' }, expr = true, desc = 'Next multi matchup' },
      ['z%'] = { key = 'z%', expr = true, mode = { 'n', 'x' }, desc = 'Previous inner matchup' },
      ['Z%'] = { key = 'Z%', expr = true, mode = { 'n', 'x' }, desc = 'Next inner matchup' },
    },
  },
}
