return {
  {
    'altermo/ultimate-autopair.nvim',
    cond = not vim.g.vscode,
    event = { 'InsertEnter', 'CmdlineEnter' },
    branch = 'v0.6',
    opts = { tabout = { enable = true }, space2 = { enable = true }, fastwarp = { faster = true } },
    config = function(_, opts)
      -- NOTE:
      -- Do not map by default
      require('ultimate-autopair.core').modes = {}
      require('ultimate-autopair').setup(opts)
    end,
  },
  {
    'kylechui/nvim-surround',
    version = '*',
    opts = {
      move_cursor = "sticky",
      keymaps = {
        insert = false,
        insert_line = false,
        normal = false,
        normal_cur = false,
        normal_line = false,
        normal_cur_line = false,
        visual = false,
        visual_line = false,
        delete = false,
        change = false,
        change_line = false,
      },
    },
  },
}
