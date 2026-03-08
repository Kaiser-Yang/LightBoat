return {
  'nvim-lualine/lualine.nvim',
  dependencies = 'nvim-tree/nvim-web-devicons',
  lazy = false,
  cond = not vim.g.vscode,
  opts = {
    options = {
      globalstatus = true,
      always_divide_middle = true,
      disabled_filetypes = {
        winbar = {
          'dapui_console',
          'dapui_stacks',
          'dapui_watches',
          'dapui_breakpoints',
          'dapui_hover',
          'dap-repl',
        },
      },
    },
  },
}
