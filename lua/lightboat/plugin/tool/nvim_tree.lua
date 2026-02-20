local u = require('lightboat.util')
return {
  'nvim-tree/nvim-tree.lua',
  cond = not vim.g.vscode,
  cmd = {
    'NvimTreeOpen',
    'NvimTreeClose',
    'NvimTreeToggle',
    'NvimTreeFocus',
    'NvimTreeRefresh',
    'NvimTreeClipboard',
    'NvimTreeFindFile',
    'NvimTreeFindFileToggle',
    'NvimTreeResize',
    'NvimTreeCollapse',
    'NvimTreeCollapseKeepBuffers',
    'NvimTreeHiTest',
  },
  opts = {
    view = {
      number = true,
      relativenumber = true,
      preserve_window_proportions = true,
    },
    renderer = {
      group_empty = true,
      indent_markers = { enable = true },
      hidden_display = 'all',
    },
    diagnostics = { enable = true, show_on_dirs = true },
    modified = { enable = true },
    filters = {
      git_ignored = true,
      dotfiles = not u.in_config_dir(),
      custom = { '^\\.git' },
    },
    actions = {
      file_popup = { open_win_config = { border = vim.o.winborder } },
      open_file = {
        window_picker = {
          exclude = {
            filetype = {
              'notify',
              'packer',
              'qf',
              'diff',
              'fugitive',
              'fugitiveblame',
              'smear-cursor',
              'snacks_notif',
              'noice',
            },
            buftype = { 'terminal', 'quickfix', 'prompt' },
          },
        },
      },
    },
  },
}
