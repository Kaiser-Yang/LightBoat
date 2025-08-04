local util = require('lightboat.util')
local disabled_filetype = { 'snacks_picker_input' }
local rep_move = require('lightboat.extra.rep_move')
local prev_matchup, next_matchup = rep_move.make('<plug>(matchup-g%)', '<plug>(matchup-%)')
local prev_multi_matchup, next_multi_matchup = rep_move.make('<plug>(matchup-[%)', '<plug>(matchup-][%)')
local prev_inner_matchup, next_inner_matchup = rep_move.make('<plug>(matchup-z%)', '<plug>(matchup-Z%)')
local M = {}
local config = require('lightboat.config')
local c
local big_file = require('lightboat.extra.big_file')

-- NOTE:
-- This requires quick typing.
-- Press y and wait will start to copy.
-- Press ys or yS quickly will start to surround.
-- ds and cs are the similar.
local operation = {
  surround = {
    ['ys'] = '<plug>(nvim-surround-normal)',
    ['yS'] = '<plug>(nvim-surround-normal-cur)',
    ['S'] = '<plug>(nvim-surround-visual)',
    ['ds'] = '<plug>(nvim-surround-delete)',
    ['cs'] = '<plug>(nvim-surround-change)',
  },
  matchup = {
    ['g%'] = prev_matchup,
    ['%'] = next_matchup,
    ['[%'] = prev_multi_matchup,
    [']%'] = next_multi_matchup,
    ['z%'] = prev_inner_matchup,
    ['Z%'] = next_inner_matchup,
  },
}

local spec = {
  {
    'altermo/ultimate-autopair.nvim',
    event = { 'InsertEnter' },
    branch = 'v0.6',
    opts = {
      bs = {
        overjumps = true, --(|foo) > bs > |foo
        space = 'balance',
        indent_ignore = true,
      },
      cr = { autoclose = true },
      space = {},
      close = { enable = false },
      config_internal_pairs = {
        { '[', ']', cmap = false, nft = disabled_filetype },
        { '(', ')', cmap = false, nft = disabled_filetype },
        { '{', '}', cmap = false, nft = disabled_filetype },
        { '"', '"', cmap = false, nft = disabled_filetype },
        { "'", "'", cmap = false, nft = disabled_filetype },
        { '`', '`', cmap = false, nft = disabled_filetype },
      },
    },
  },
  {
    'kylechui/nvim-surround',
    version = '*',
    opts = {
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
    keys = {},
  },
  {
    'andymass/vim-matchup',
    init = function() vim.g.matchup_matchparen_enabled = 0 end,
    -- NOTE:
    -- we can not lazy load this plugin
    lazy = false,
    opts = {},
    keys = {},
  },
  {
    'windwp/nvim-ts-autotag',
    ft = {
      'astro',
      'glimmer',
      'handlebars',
      'html',
      'javascript',
      'jsx',
      'liquid',
      'markdown',
      'php',
      'rescript',
      'svelte',
      'tsx',
      'twig',
      'typescript',
      'vue',
      'xml',
    },
    opts = { opts = { enable_close_on_slash = true } },
  },
  {
    'HiPhish/rainbow-delimiters.nvim',
    lazy = false,
  },
}

function M.spec() return spec end

function M.clear()
  assert(spec[1][1] == 'altermo/ultimate-autopair.nvim')
  spec[1].opts.space.check_box_ft = nil
  assert(spec[2][1] == 'kylechui/nvim-surround')
  spec[2].keys = {}
  assert(spec[3][1] == 'andymass/vim-matchup')
  spec[3].keys = {}
end

M.setup = util.setup_check_wrap('lightboat.plugin.code.pair', function()
  c = config.get()
  if not c.pair.enabled then return nil end
  assert(spec[1][1] == 'altermo/ultimate-autopair.nvim')
  spec[1].opts.space.check_box_ft = c.extra.markdown_fts
  assert(spec[2][1] == 'kylechui/nvim-surround')
  spec[2].keys = util.key.get_lazy_keys(operation.surround, c.pair.keys)
  assert(spec[3][1] == 'andymass/vim-matchup')
  spec[3].keys = util.key.get_lazy_keys(operation.matchup, c.pair.keys)
  vim.g.rainbow_delimiters = vim.tbl_extend('force', {
    highlight = {
      'RainbowDelimiterRed',
      'RainbowDelimiterOrange',
      'RainbowDelimiterYellow',
      'RainbowDelimiterMagenta',
      'RainbowDelimiterTeal',
      'RainbowDelimiterGrey',
      'RainbowDelimiterCyan',
      'RainbowDelimiterViolet',
      'RainbowDelimiterBlue',
      'RainbowDelimiterGreen',
    },
    -- PERF:
    -- This plugin may cause performance issues with large files.
    condition = function(buf) return not big_file.is_big_file(buf) end,
  }, vim.g.rainbow_delimiters or {})
  vim.api.nvim_set_hl(0, 'RainbowDelimiterRed', { fg = '#f38ba8' })
  vim.api.nvim_set_hl(0, 'RainbowDelimiterOrange', { fg = '#fab387' })
  vim.api.nvim_set_hl(0, 'RainbowDelimiterYellow', { fg = '#f9e2af' })
  vim.api.nvim_set_hl(0, 'RainbowDelimiterMagenta', { fg = '#FF79C6' })
  vim.api.nvim_set_hl(0, 'RainbowDelimiterTeal', { fg = '#20B2CE' })
  vim.api.nvim_set_hl(0, 'RainbowDelimiterGrey', { fg = '#9CA0A4' })
  vim.api.nvim_set_hl(0, 'RainbowDelimiterCyan', { fg = '#5AF7EE' })
  vim.api.nvim_set_hl(0, 'RainbowDelimiterViolet', { fg = '#B253DF' })
  vim.api.nvim_set_hl(0, 'RainbowDelimiterBlue', { fg = '#617FFF' })
  vim.api.nvim_set_hl(0, 'RainbowDelimiterGreen', { fg = '#98C349' })
  return spec
end, M.clear)

return M
