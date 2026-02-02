local util = require('lightboat.util')
local big_file = require('lightboat.extra.big_file')
local M = {}
local group
local config = require('lightboat.config')
local c

function M.to_select_wrap(query_string, query_group)
  return function() require('nvim-treesitter-textobjects.select').select_textobject(query_string, query_group) end
end

--- @param direction 'next'|'previous'
function M.to_swap_wrap(direction, query_string)
  return function() require('nvim-treesitter-textobjects.swap')['swap_' .. direction](query_string) end
end

--- @param direction 'next'|'previous'
--- @param position 'start'|'end'|''
local function to_move_wrap(direction, position, query_string)
  return function() require('nvim-treesitter-textobjects.move')['goto_' .. direction .. '_' .. position](query_string) end
end

local rep_move = require('lightboat.extra.rep_move')
-- HACK:
-- This below can not cycle
M.prev_function_start, M.next_function_start =
  rep_move.make(to_move_wrap('previous', 'start', '@function.outer'), to_move_wrap('next', 'start', '@function.outer'))
M.prev_class_start, M.next_class_start =
  rep_move.make(to_move_wrap('previous', 'start', '@class.outer'), to_move_wrap('next', 'start', '@class.outer'))
M.prev_loop_start, M.next_loop_start =
  rep_move.make(to_move_wrap('previous', 'start', '@loop.outer'), to_move_wrap('next', 'start', '@loop.outer'))
M.prev_block_start, M.next_block_start =
  rep_move.make(to_move_wrap('previous', 'start', '@block.outer'), to_move_wrap('next', 'start', '@block.outer'))
M.prev_return_start, M.next_return_start =
  rep_move.make(to_move_wrap('previous', 'start', '@return.outer'), to_move_wrap('next', 'start', '@return.outer'))
M.prev_parameter_start, M.next_parameter_start = rep_move.make(
  to_move_wrap('previous', 'start', '@parameter.inner'),
  to_move_wrap('next', 'start', '@parameter.inner')
)
M.prev_if_start, M.next_if_start = rep_move.make(
  to_move_wrap('previous', 'start', '@conditional.outer'),
  to_move_wrap('next', 'start', '@conditional.outer')
)
M.prev_function_end, M.next_function_end =
  rep_move.make(to_move_wrap('previous', 'end', '@function.outer'), to_move_wrap('next', 'end', '@function.outer'))
M.prev_class_end, M.next_class_end =
  rep_move.make(to_move_wrap('previous', 'end', '@class.outer'), to_move_wrap('next', 'end', '@class.outer'))
M.prev_loop_end, M.next_loop_end =
  rep_move.make(to_move_wrap('previous', 'end', '@loop.outer'), to_move_wrap('next', 'end', '@loop.outer'))
M.prev_block_end, M.next_block_end =
  rep_move.make(to_move_wrap('previous', 'end', '@block.outer'), to_move_wrap('next', 'end', '@block.outer'))
M.prev_return_end, M.next_return_end =
  rep_move.make(to_move_wrap('previous', 'end', '@return.outer'), to_move_wrap('next', 'end', '@return.outer'))
M.prev_parameter_end, M.next_parameter_end =
  rep_move.make(to_move_wrap('previous', 'end', '@parameter.inner'), to_move_wrap('next', 'end', '@parameter.inner'))
M.prev_if_end, M.next_if_end = rep_move.make(
  to_move_wrap('previous', 'end', '@conditional.outer'),
  to_move_wrap('next', 'end', '@conditional.outer')
)
local operation = {
  ['af'] = M.to_select_wrap('@function.outer'),
  ['if'] = M.to_select_wrap('@function.inner'),
  ['ac'] = M.to_select_wrap('@class.outer'),
  ['ic'] = M.to_select_wrap('@class.inner'),
  ['ab'] = M.to_select_wrap('@block.outer'),
  ['ib'] = M.to_select_wrap('@block.inner'),
  ['ai'] = M.to_select_wrap('@conditional.outer'),
  ['ii'] = M.to_select_wrap('@conditional.inner'),
  ['al'] = M.to_select_wrap('@loop.outer'),
  ['il'] = M.to_select_wrap('@loop.inner'),
  ['ar'] = M.to_select_wrap('@return.outer'),
  ['ir'] = M.to_select_wrap('@return.inner'),
  ['ap'] = M.to_select_wrap('@parameter.outer'),
  ['ip'] = M.to_select_wrap('@parameter.inner'),
  ['s'] = '<cmd>WhichKey n s<cr>',
  ['snf'] = M.to_swap_wrap('next', '@function.outer'),
  ['snc'] = M.to_swap_wrap('next', '@class.outer'),
  ['snl'] = M.to_swap_wrap('next', '@loop.outer'),
  ['snb'] = M.to_swap_wrap('next', '@block.outer'),
  ['snr'] = M.to_swap_wrap('next', '@return.outer'),
  ['snp'] = M.to_swap_wrap('next', '@parameter.inner'),
  ['sni'] = M.to_swap_wrap('next', '@conditional.outer'),
  ['spf'] = M.to_swap_wrap('previous', '@function.outer'),
  ['spc'] = M.to_swap_wrap('previous', '@class.outer'),
  ['spl'] = M.to_swap_wrap('previous', '@loop.outer'),
  ['spb'] = M.to_swap_wrap('previous', '@block.outer'),
  ['spr'] = M.to_swap_wrap('previous', '@return.outer'),
  ['spp'] = M.to_swap_wrap('previous', '@parameter.inner'),
  ['spi'] = M.to_swap_wrap('previous', '@conditional.outer'),
  ['[f'] = M.prev_function_start,
  [']f'] = M.next_function_start,
  ['[c'] = M.prev_class_start,
  [']c'] = M.next_class_start,
  ['[l'] = M.prev_loop_start,
  [']l'] = M.next_loop_start,
  ['[b'] = M.prev_block_start,
  [']b'] = M.next_block_start,
  ['[r'] = M.prev_return_start,
  [']r'] = M.next_return_start,
  ['[p'] = M.prev_parameter_start,
  [']p'] = M.next_parameter_start,
  ['[i'] = M.prev_if_start,
  [']i'] = M.next_if_start,
  ['[F'] = M.prev_function_end,
  [']F'] = M.next_function_end,
  ['[C'] = M.prev_class_end,
  [']C'] = M.next_class_end,
  ['[L'] = M.prev_loop_end,
  [']L'] = M.next_loop_end,
  ['[B'] = M.prev_block_end,
  [']B'] = M.next_block_end,
  ['[R'] = M.prev_return_end,
  [']R'] = M.next_return_end,
  ['[P'] = M.prev_parameter_end,
  [']P'] = M.next_parameter_end,
  ['[I'] = M.prev_if_end,
  [']I'] = M.next_if_end,
}

local spec = {
  {
    'nvim-treesitter/nvim-treesitter',
    cond = not vim.g.vscode,
    branch = 'main',
    build = ':TSUpdate',
    opts = {},
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    opts = { select = { lookahead = true }, move = { set_jumps = true } },
    keys = {},
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    cond = not vim.g.vscode,
    opts = {
      max_lines = 3,
      on_attach = function(buf) return not big_file.is_big_file(buf) end,
    },
  },
}

function M.spec() return spec end

function M.clear()
  assert(spec[2][1] == 'nvim-treesitter/nvim-treesitter-textobjects')
  spec[2].keys = {}
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
end

M.setup = util.setup_check_wrap('lightboat.plugin.treesitter', function()
  c = config.get().treesitter
  if not c.enabled then return nil end
  assert(spec[2][1] == 'nvim-treesitter/nvim-treesitter-textobjects')
  spec[2].keys = util.key.get_lazy_keys(operation, c.keys)
  group = vim.api.nvim_create_augroup('LightBoatTreesitter', {})
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'BigFileDetector',
    callback = function(ev)
      if not ev.data then return end
      if vim.treesitter.highlighter.active[ev.buf] then
        vim.treesitter.stop()
        vim.schedule(function() vim.notify('Treesitter stopped for big file', vim.log.levels.WARN) end)
      end
      local ok, ts_context = pcall(require, 'treesitter-context')
      if not ok or not ts_context.enabled() then return end
      -- HACK:
      -- There is no information about attached buffer, so we can not notify
      -- that the plugin was disabled for this buffeer
      ts_context.enable() -- Restart to avoid large memery use for large files
    end,
  })
  if vim.g.vscode then return spec end
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(args)
      if big_file.is_big_file(args.buf) then return end
      pcall(vim.treesitter.start)
    end,
  })
  return spec
end, M.clear)

return M
