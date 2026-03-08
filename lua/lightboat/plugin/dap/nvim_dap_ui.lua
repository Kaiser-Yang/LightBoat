return {
  'rcarriga/nvim-dap-ui',
  lazy = true,
  dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
  opts = {
    floating = { border = vim.o.winborder },
    icons = (function()
      local fc = vim.opt.fillchars:get() or {}
      local collapsed = fc.foldclose or ''
      local expanded = fc.foldopen or ''
      return {
        collapsed = collapsed,
        current_frame = collapsed,
        expanded = expanded,
      }
    end)(),
  },
}
