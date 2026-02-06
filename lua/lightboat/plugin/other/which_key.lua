-- PERF:
-- When enabling the registers plugin, (default on, opts.plugins.registers = true)
-- it will cause a performance problem when the content is large.
return {
  'folke/which-key.nvim',
  cond = not vim.g.vscode,
  event = 'VeryLazy',
  opts = {
    delay = vim.o.timeoutlen,
    sort = { 'alphanum', 'local', 'order', 'group', 'mod' },
    filter = function(mapping)
      -- BUG:
      -- See https://github.com/folke/which-key.nvim/issues/1033
      if mapping.lhs:match('^z') then return false end
      if (mapping.mode == 'o' or mapping.mode == 'x' or mapping.mode == 'v') and not mapping.lhs:match('^[ai%[%]]') then
        return false
      end
      return true
    end,
    defer = function(ctx) return ctx.mode == 'V' or ctx.mode == '<C-V>' end,
  },
}
