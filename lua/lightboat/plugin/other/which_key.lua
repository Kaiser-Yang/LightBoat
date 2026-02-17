return {
  'Kaiser-Yang/which-key.nvim',
  cond = not vim.g.vscode,
  event = 'VeryLazy',
  opts = {
    delay = function() return vim.o.timeoutlen end,
    sort = { 'alphanum', 'local', 'order', 'group', 'mod' },
    keys = { scroll_down = '', scroll_up = '' },
    triggers = { { '<auto>', mode = 'icnxo' }, { 'a', mode = 'x' }, { 'i', mode = 'x' } },
    icons = { rules = false },
    -- BUG:
    -- See https://github.com/folke/which-key.nvim/issues/1033
    filter = function(mapping)
      if mapping.desc == 'Nop' then return false end
      -- stylua: ignore start
      if
        (mapping.mode == 'n' or mapping.mode == 'o' or mapping.mode == 'x' or mapping.mode == 'v')
        and vim.tbl_contains(
          { 'b', 'c', 'd', 'e', 'f', 'h', 'j', 'k', 'l', 'r', 't', 'v', 'w', 'y',
            'B', 'E', 'F', 'G', 'T', 'V', 'W',
            '~', '$', '%', ',', ';', '<', '>', '/', '?', '^', '0' }, mapping.lhs)
      then
      -- stylua: ignore end
        return false
      end
      return true
    end,
    defer = function() return false end,
  },
}
