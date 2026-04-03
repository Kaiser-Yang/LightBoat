local util = require('lightboat.util')
local rep_move = require('lightboat.extra.rep_move')
local prev_matchup, next_matchup = rep_move.make('<plug>(matchup-g%)', '<plug>(matchup-%)')
local prev_multi_matchup, next_multi_matchup = rep_move.make('<plug>(matchup-[%)', '<plug>(matchup-]%)')
local prev_inner_matchup, next_inner_matchup = rep_move.make('<plug>(matchup-Z%)', '<plug>(matchup-z%)')
local M = {}

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

M.setup = util.setup_check_wrap('lightboat.plugin.code.pair', function()
  vim.api.nvim_create_autocmd('User', {
    pattern = 'BigFileDetector',
    callback = function(ev)
      if not ev.data then return end
      local ok, internal = pcall(require, 'nvim-ts-autotag.internal')
      if not ok then return end
      internal.detach(ev.buf)
    end,
  })
  vim.g.rainbow_delimiters = vim.tbl_extend('force', {
    -- PERF:
    -- This plugin may cause performance issues with large files.
    condition = function(buf)
      return (not c.pair.rainbow_limit_lines or vim.api.nvim_buf_line_count(buf) <= c.pair.rainbow_limit_lines)
        and not big_file.is_big_file(buf)
    end,
  }, vim.g.rainbow_delimiters or {})
end, M.clear)
