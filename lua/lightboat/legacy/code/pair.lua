local util = require('lightboat.util')
local feedkeys = util.key.feedkeys
local disabled_filetype = { 'snacks_picker_input' }
local rep_move = require('lightboat.extra.rep_move')
local prev_matchup, next_matchup = rep_move.make('<plug>(matchup-g%)', '<plug>(matchup-%)')
local prev_multi_matchup, next_multi_matchup = rep_move.make('<plug>(matchup-[%)', '<plug>(matchup-]%)')
local prev_inner_matchup, next_inner_matchup = rep_move.make('<plug>(matchup-Z%)', '<plug>(matchup-z%)')
local M = {}
local config = require('lightboat.config')
local c
local group
local big_file = require('lightboat.extra.big_file')

local operation = {
  matchup = {
    ['g%'] = prev_matchup,
    ['%'] = next_matchup,
    ['[%'] = prev_multi_matchup,
    [']%'] = next_multi_matchup,
    ['Z%'] = prev_inner_matchup,
    ['z%'] = next_inner_matchup,
  },
}

local spec = {
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
    'Kaiser-Yang/nvim-ts-autotag',
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
    cond = not vim.g.vscode,
    lazy = false,
  },
}

function M.spec() return spec end

function M.clear()
  assert(spec[1][1] == 'altermo/ultimate-autopair.nvim')
  spec[1].opts.space.check_box_ft = nil
  assert(spec[3][1] == 'andymass/vim-matchup')
  spec[3].keys = {}
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
end

M.setup = util.setup_check_wrap('lightboat.plugin.code.pair', function()
  c = config.get()
  for _, s in ipairs(spec) do
    s.enabled = c.pair.enabled
  end
  assert(spec[1][1] == 'altermo/ultimate-autopair.nvim')
  spec[1].opts.space.check_box_ft = c.extra.markdown_fts
  assert(spec[3][1] == 'andymass/vim-matchup')
  spec[3].keys = util.key.get_lazy_keys(operation.matchup, c.pair.keys)
  group = vim.api.nvim_create_augroup('LightBoatPair', {})
  vim.api.nvim_create_autocmd('User', {
    pattern = 'BigFileDetector',
    group = group,
    callback = function(ev)
      if not ev.data then return end
      local ok, internal = pcall(require, 'nvim-ts-autotag.internal')
      if not ok then return end
      internal.detach(ev.buf)
    end,
  })
  if vim.g.vscode then return spec end
  vim.g.rainbow_delimiters = vim.tbl_extend('force', {
    highlight = {
      'RainbowDelimiterRed',
      'RainbowDelimiterMagenta',
      'RainbowDelimiterTeal',
      'RainbowDelimiterCyan',
      'RainbowDelimiterOrange',
      'RainbowDelimiterYellow',
      'RainbowDelimiterViolet',
      'RainbowDelimiterBlue',
      'RainbowDelimiterGreen',
      'RainbowDelimiterGrey',
    },
    -- PERF:
    -- This plugin may cause performance issues with large files.
    condition = function(buf)
      return (not c.pair.rainbow_limit_lines or vim.api.nvim_buf_line_count(buf) <= c.pair.rainbow_limit_lines)
        and not big_file.is_big_file(buf)
    end,
  }, vim.g.rainbow_delimiters or {})
  util.set_hls({
    { 0, 'RainbowDelimiterRed', { fg = '#f38ba8' } },
    { 0, 'RainbowDelimiterMagenta', { fg = '#FF79C6' } },
    { 0, 'RainbowDelimiterTeal', { fg = '#20B2CE' } },
    { 0, 'RainbowDelimiterCyan', { fg = '#5AF7EE' } },
    { 0, 'RainbowDelimiterOrange', { fg = '#e09a5a' } },
    { 0, 'RainbowDelimiterYellow', { fg = '#d7e07b' } },
    { 0, 'RainbowDelimiterViolet', { fg = '#B253DF' } },
    { 0, 'RainbowDelimiterBlue', { fg = '#617FFF' } },
    { 0, 'RainbowDelimiterGreen', { fg = '#98C349' } },
    { 0, 'RainbowDelimiterGrey', { fg = '#9CA0A4' } },
  })
  return spec
end, M.clear)

return M
