return {
  'Kaiser-Yang/which-key.nvim',
  cond = not vim.g.vscode,
  event = 'VeryLazy',
  opts = {
    delay = function() return vim.o.timeoutlen end,
    sort = { 'alphanum', 'local', 'order', 'group', 'mod' },
    keys = { scroll_down = '', scroll_up = '' },
    triggers = { { '<auto>', mode = 'icnxo' }, { 'a', mode = 'x' }, { 'i', mode = 'x' } },
    -- BUG:
    -- See https://github.com/folke/which-key.nvim/issues/1033
    filter = function(mapping)
      if
        (mapping.mode == 'o' or mapping.mode == 'x' or mapping.mode == 'v')
          and mapping.lhs ~= 's'
          and mapping.lhs ~= 'S'
          and (#mapping.lhs == 1 or mapping.lhs:match('^<.*>$'))
        or mapping.desc == 'Nop'
      then
        return false
      end
      return true
    end,
    defer = function() return false end,
  },
}
