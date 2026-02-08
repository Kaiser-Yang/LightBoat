-- PERF:
-- When enabling the registers plugin, (default on, opts.plugins.registers = true)
-- it will cause a performance problem when the content is large.
return {
  'Kaiser-Yang/which-key.nvim',
  cond = not vim.g.vscode,
  event = 'VeryLazy',
  opts = {
    delay = function() return vim.o.timeoutlen end,
    sort = { 'alphanum', 'local', 'order', 'group', 'mod' },
    triggers = { { '<auto>', mode = 'icnxso' } },
    filter = function(mapping)
      -- BUG:
      -- See https://github.com/folke/which-key.nvim/issues/1033
      if mapping.lhs:match('^z') then return false end
      if (mapping.mode == 'o' or mapping.mode == 'x' or mapping.mode == 'v') and not mapping.lhs:match('^[sSai%[%]]') then
        return false
      end
      return true
    end,
  },
}
