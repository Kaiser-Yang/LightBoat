local util = require('lightboat.util')
local feedkeys = util.key.feedkeys
local disabled_filetype = { 'snacks_picker_input' }
local rep_move = require('lightboat.extra.rep_move')
local prev_matchup, next_matchup = rep_move.make('<plug>(matchup-g%)', '<plug>(matchup-%)')
local prev_multi_matchup, next_multi_matchup = rep_move.make('<plug>(matchup-[%)', '<plug>(matchup-][%)')
local prev_inner_matchup, next_inner_matchup = rep_move.make('<plug>(matchup-z%)', '<plug>(matchup-Z%)')
local M = {}
local config = require('lightboat.config')
local c
local group
local big_file = require('lightboat.extra.big_file')

local operation = {
  surround = {
    ['ys'] = '<plug>(nvim-surround-normal)',
    ['yS'] = '<plug>(nvim-surround-normal)$',
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
    -- PERF:
    -- https://github.com/altermo/ultimate-autopair.nvim/issues/112
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
        { '[', ']', cmap = false },
        { '(', ')', cmap = false },
        { '{', '}', cmap = false },
        { '"', '"', cmap = false },
        { "'", "'", cmap = false },
        { '`', '`', cmap = false },
      },
      extensions = { filetype = { nft = disabled_filetype } },
    },
  },
  {
    -- PERF:
    -- https://github.com/kylechui/nvim-surround/issues/398
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
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
end

M.setup = util.setup_check_wrap('lightboat.plugin.code.pair', function()
  c = config.get()
  if not c.pair.enabled then return nil end
  assert(spec[1][1] == 'altermo/ultimate-autopair.nvim')
  spec[1].opts.space.check_box_ft = c.extra.markdown_fts
  assert(spec[2][1] == 'kylechui/nvim-surround')
  spec[2].keys = util.key.get_lazy_keys(operation.surround, c.pair.keys)
  table.insert(spec[2].keys, {
    's',
    function()
      local res
      if vim.v.operator == 'y' and c.pair.keys['ys'].key == 'ys' then
        res = '<plug>(nvim-surround-normal)'
      elseif vim.v.operator == 'd' and c.pair.keys['ds'].key == 'ds' then
        res = '<plug>(nvim-surround-delete)'
      elseif vim.v.operator == 'c' and c.pair.keys['cs'].key == 'cs' then
        res = '<plug>(nvim-surround-change)'
      elseif vim.v.operator == 'g@' then
        res = '<plug>(nvim-surround-normal-cur)'
      end
      if res then vim.schedule(function() feedkeys(res, 'n') end) end
      return '<esc>'
    end,
    expr = true,
    mode = 'o',
    desc = 'Change, delete or add a surrounding pair (operator pending mode)',
  })
  table.insert(spec[2].keys, {
    'S',
    function()
      local res
      if vim.v.operator == 'y' and c.pair.keys['yS'].key == 'yS' then res = '<plug>(nvim-surround-normal-cur)' end
      if res then vim.schedule(function() feedkeys(res, 'n') end) end
      return '<esc>'
    end,
    mode = 'o',
    desc = 'Change, delete or add a surrounding pair (operator pending mode, line-wise)',
  })
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
    condition = function(buf)
      return not big_file.is_big_file(buf)
        and (not c.pair.rainbow_limit_lines or vim.api.nvim_buf_line_count(buf) <= c.pair.rainbow_limit_lines)
    end,
  }, vim.g.rainbow_delimiters or {})
  util.set_hls({
    { 0, 'RainbowDelimiterRed', { fg = '#f38ba8' } },
    { 0, 'RainbowDelimiterOrange', { fg = '#fab387' } },
    { 0, 'RainbowDelimiterYellow', { fg = '#f9e2af' } },
    { 0, 'RainbowDelimiterMagenta', { fg = '#FF79C6' } },
    { 0, 'RainbowDelimiterTeal', { fg = '#20B2CE' } },
    { 0, 'RainbowDelimiterGrey', { fg = '#9CA0A4' } },
    { 0, 'RainbowDelimiterCyan', { fg = '#5AF7EE' } },
    { 0, 'RainbowDelimiterViolet', { fg = '#B253DF' } },
    { 0, 'RainbowDelimiterBlue', { fg = '#617FFF' } },
    { 0, 'RainbowDelimiterGreen', { fg = '#98C349' } },
  })
  local function disable_autotag_for_large_files(args)
    if not big_file.is_big_file(args.buf) then return end
    local ok1, _ = pcall(vim.keymap.del, 'i', '/', { buffer = args.buf })
    local ok2, _ = pcall(vim.keymap.del, 'i', '>', { buffer = args.buf })
    if ok1 or ok2 then
      vim.schedule(
        function() vim.notify('Disabled nvim-ts-autotag for current file due to its size.', vim.log.levels.WARN) end
      )
    end
  end
  group = vim.api.nvim_create_augroup('LightBoatPair', {})
  vim.api.nvim_create_autocmd({ 'Filetype', 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = disable_autotag_for_large_files,
  })
  return spec
end, M.clear)

return M
