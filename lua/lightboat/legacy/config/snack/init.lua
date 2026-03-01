local function default_cwd()
  local root_markers = require('lightboat.config').get().extra.root_markers or {}
  return vim.fs.root(vim.fn.getcwd(), root_markers) or vim.fs.root(0, root_markers)
end

local function save_as_last_when_not_empty(picker)
  local filter = picker.input.filter
  return (filter.pattern and not filter.pattern:match('^%s*$') or filter.search and not filter.search:match('^%s*$'))
    and picker.list.items
    and #picker.list.items > 0
end

local rg_ignore_patterns = {
  '*.git',
  '*.o',
  '*.out',
  '*.exe',
  '*.png',
  '*.gif',
  '*.jpg',
  '*.so',
  '*.a',
  '*.dll',
  '*.dylib',
  '*.class',
  '*.jar',
  '*.zip',
  '*.tar.gz',
}
local util = require('lightboat.util')

return {
  enabled = true,
  scroll_min_lines = 2,
  scroll_max_lines = 1024,
  keys = {
    ['<c-y>'] = {
      key = '<c-y>',
      desc = 'Resume last picker',
      opts = {},
    },
    ['z='] = { key = 'z=', desc = 'Spelling suggestions', opts = { layout = { preset = 'select' } } },
    ['<c-p>'] = {
      key = '<c-p>',
      desc = 'Toggle find Files',
      opts = {
        cwd = default_cwd,
        cmd = 'rg',
        hidden = util.in_config_dir,
        pattern = function() return vim.bo.filetype == 'snacks_picker_input' and vim.api.nvim_get_current_line() or '' end,
        exclude = rg_ignore_patterns,
        layout = { hidden = { 'preview' } },
        save_as_last = save_as_last_when_not_empty,
      },
    },
    ['<c-f>'] = {
      key = '<c-f>',
      desc = 'Toggle Live Grep',
      opts = {
        cwd = default_cwd,
        cmd = 'rg',
        hidden = util.in_config_dir,
        search = function() return vim.bo.filetype == 'snacks_picker_input' and vim.api.nvim_get_current_line() or '' end,
        exclude = rg_ignore_patterns,
        save_as_last = save_as_last_when_not_empty,
      },
    },
    ['<leader><leader>'] = {
      key = '<leader><leader>',
      prev = 'big_file_check',
      desc = 'Current buffer fuzzy find',
      opts = { layout = { preset = 'select' } },
    },
    ['<leader>r'] = { key = '<leader>r', desc = 'Run and compile' },
    ['<leader>sp'] = {
      key = '<leader>sp',
      prev = { 'disable_in_gitcommit', 'check_markdown_fts' },
      desc = 'Paste image from the file picker',
      opts = {
        cwd = default_cwd,
        cmd = 'rg',
        hidden = util.in_config_dir,
        ft = { 'gif', 'jpg', 'jpeg', 'png', 'webp' },
        confirm = function(self, item, _)
          self:close()
          require('img-clip').paste_image({}, default_cwd() .. '/' .. item.file)
        end,
      },
    },
  },
}
