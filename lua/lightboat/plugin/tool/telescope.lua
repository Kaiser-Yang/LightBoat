local u = require('lightboat.util')
local function find_command()
  local res = { 'rg', '--files', '--color', 'never', '-g', '!.git' }
  if u.in_config_dir() then table.insert(res, '--hidden') end
  return res
end
local additional_args = function()
  local res = { '-g', '!.git' }
  if u.in_config_dir() then table.insert(res, '--hidden') end
  return res
end
return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-frecency.nvim',
    'nvim-telescope/telescope-live-grep-args.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      enabled = vim.fn.executable('make') == 1 and (vim.fn.executable('gcc') == 1 or vim.fn.executable('clang') == 1),
    },
  },
  cmd = { 'Telescope' },
  opts = {
    defaults = {
      dynamic_preview_title = true,
      sorting_strategy = 'ascending',
      default_mappings = {},
      layout_config = {
        horizontal = { prompt_position = 'top' },
        width = { padding = 0 },
        height = { padding = 0 },
      },
      cache_picker = { ignore_empty_prompt = true },
    },
    pickers = {
      registers = {
        initial_mode = 'normal',
        theme = 'cursor',
      },
      gpre_string = { theme = 'ivy', layout_config = { height = 0.4 } },
      find_files = { prompt_title = 'Find File', find_command = find_command },
      live_grep = {
        additional_args = additional_args,
      },
      grep_string = { additional_args = additional_args },
    },
    extensions = {
      live_grep_args = {
        additional_args = additional_args,
        prompt_title = 'Live Grep',
      },
      frecency = {
        -- BUG:
        -- https://github.com/nvim-telescope/telescope-frecency.nvim/issues/316
        theme = 'dropdown',
        previewer = false,
        layout_config = { anchor = 'N', anchor_padding = 0 },
        prompt_title = 'Find File Frecency',
        -- HACK:
        -- https://github.com/nvim-telescope/telescope-frecency.nvim/issues/335
        workspace_scan_cmd = find_command(),
        -- BUG:
        -- https://github.com/nvim-telescope/telescope-frecency.nvim/pull/334
        matcher = 'fuzzy',
        db_version = 'v2',
        preceding = 'opened',
        hide_current_buffer = true,
        show_filter_column = false,
        ignore_register = function(buffer) return not vim.bo[buffer].buflisted or vim.bo[buffer].buftype ~= '' end,
      },
    },
  },
}
