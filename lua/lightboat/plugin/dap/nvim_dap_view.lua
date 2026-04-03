return {
  'igorlfs/nvim-dap-view',
  cond = not vim.g.vscode,
  cmd = {
    'DapViewOpen',
    'DapViewClose',
    'DapViewToggle',
    'DapViewWatch',
    'DapViewJump',
    'DapViewShow',
    'DapViewNavigate',
  },
  opts = {
    winbar = {
      show = true,
      sections = { 'console', 'scopes', 'watches', 'breakpoints', 'repl', 'threads', 'exceptions' },
      default_section = 'console',
      controls = {
        enabled = true,
        position = 'right',
        buttons = {
          'terminate',
          'play',
          'run_last',

          'disconnect',

          'step_back',
          'step_over',
          'step_into',
          'step_out',
        },
      },
    },
    icons = (function()
      local fc = vim.opt.fillchars:get() or {}
      local collapsed = fc.foldclose or ''
      local expanded = fc.foldopen or ''
      return {
        collapsed = collapsed,
        expanded = expanded,
      }
    end)(),
    help = { border = vim.o.winborder },
  },
}
