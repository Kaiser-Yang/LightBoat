local operation = {
  ['gca'] = '<plug>(git_conflict-ancestor)',
  ['gcb'] = '<plug>(git-conflict-both)',
  ['gcc'] = '<plug>(git-conflict-ours)',
  ['gci'] = '<plug>(git-conflict-theirs)',
  ['gcn'] = '<plug>(git-conflict-none)',
}
return {
  'akinsho/git-conflict.nvim',
  cond = not vim.g.vscode,
  enabled = vim.fn.executable('git') == 1,
  version = '*',
  lazy = false,
  opts = {
    default_mappings = false,
    disable_diagnostics = true,
  },
}
