return {
  'folke/noice.nvim',
  dependencies = 'MunifTanjim/nui.nvim',
  event = 'VeryLazy',
  cond = not vim.g.vscode,
  opts = {
    lsp = {
      hover = { enabled = false },
      signature = { enabled = false },
      documentation = { enabled = false },
    },
    presets = {
      long_message_to_split = true,
      command_palette = { views = { cmdline_popup = { position = { row = 1, col = '50%' } } } },
    },
    popupmenu = { enabled = false },
    messages = { view_search = false },
    routes = {
      -- BUG:
      -- See https://github.com/folke/noice.nvim/issues/1097
      -- This below is a workaround to show shell output messages properly
      {
        filter = { event = 'msg_show', kind = { 'shell_out', 'shell_err', 'shell_ret' } },
        view = 'messages',
        opts = { skip = false, replace = false },
      },
    },
  },
}
