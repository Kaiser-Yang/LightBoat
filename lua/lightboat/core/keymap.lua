local c = require('lightboat.config').get().keymap
if not c.enabled then return end
local util = require('lightboat.util')
local map = util.key.set
local convert = util.key.convert
local feedkeys = util.key.feedkeys
local rep_move = require('lightboat.extra.rep_move')
local prev_find, next_find = rep_move.make('F', 'f')
local prev_till, next_till = rep_move.make('T', 't')
local prev_word, next_word = rep_move.make('b', 'w')
local prev_big_word, next_big_word = rep_move.make('B', 'W')
local prev_end_word, next_end_word = rep_move.make('ge', 'e')
local prev_big_end_word, next_big_end_word = rep_move.make('gE', 'E')
local prev_search, next_search = rep_move.make('N', 'n')
local prev_fold, next_fold = rep_move.make('zk', 'zj')
local prev_misspell, next_misspell = rep_move.make('[s', ']s')
local prev_open_fold, next_open_fold = rep_move.make('[z', ']z')

local operation = {
  ['<leader>ay'] = function()
    -- HACK:
    -- highlight when the file is small?
    vim.fn.setreg('+', vim.api.nvim_buf_get_lines(0, 0, -1, false), 'l')
    local line_count = vim.api.nvim_buf_line_count(0)
    vim.notify(string.format('Yanked %d lines to + register', line_count), nil, { title = 'Yank' })
  end,
  ['<m-x>'] = '"+d',
  ['<m-a>'] = function()
    if Snacks then
      vim.g.snacks_animate_scroll = false
      vim.schedule(function() vim.g.snacks_animate_scroll = true end)
    end
    local res
    if vim.fn.mode() == 'n' then
      res = 'gg0vG$'
    else
      res = '<esc>gg0vG$'
    end
    feedkeys(res, 'n')
  end,
  ['<c-u>'] = function()
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], #line:match('^%s*') })
    vim.api.nvim_set_current_line(line:match('^%s*') .. line:sub(cursor_col + 1))
  end,
  ['<c-w>'] = function()
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    local line_len = #vim.api.nvim_get_current_line()
    local res = '<c-o><cmd>normal '
    if cursor_col == line_len then
      res = res .. 'vlbc<cr>'
    else
      res = res .. 'hvbx<cr>'
    end
    feedkeys(res, 'n')
  end,
  ['<c-a>'] = function()
    local res
    if vim.fn.mode() == 'c' then
      res = '<home>'
    elseif vim.fn.mode() ~= 'n' then
      res = '<c-o>^'
    else
      res = '^'
    end
    return res
  end,
  ['<c-e>'] = '<end>',
  ['<leader>l'] = '<cmd>set splitright<cr><cmd>vsplit<cr><cmd>set nosplitright<cr>',
  ['<leader>j'] = '<cmd>set splitbelow<cr><cmd>split<cr><cmd>set nosplitbelow<cr>',
  ['<leader>h'] = '<cmd>vsplit<cr>',
  ['<leader>k'] = '<cmd>split<cr>',
  ['='] = '<cmd>wincmd =<cr>',
  ['<c-h>'] = '<c-w>h',
  ['<c-j>'] = '<c-w>j',
  ['<c-k>'] = '<c-w>k',
  ['<c-l>'] = '<c-w>l',
  ['<leader>T'] = '<cmd>tab split<cr>',
  ['<leader>t2'] = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
  ['<leader>t4'] = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
  ['<leader>t8'] = function()
    vim.bo.tabstop = 8
    vim.bo.shiftwidth = 8
  end,
  ['<leader>tt'] = function()
    vim.bo.expandtab = not vim.bo.expandtab
    local msg = vim.bo.expandtab and 'Expandtab enabled' or 'Expandtab disabled'
    vim.notify(msg, nil, { title = 'Settings' })
  end,
  ['F'] = prev_find,
  ['T'] = prev_till,
  ['f'] = next_find,
  ['t'] = next_till,
  ['b'] = prev_word,
  ['w'] = next_word,
  ['B'] = prev_big_word,
  ['W'] = next_big_word,
  ['ge'] = prev_end_word,
  ['e'] = next_end_word,
  ['gE'] = prev_big_end_word,
  ['E'] = next_big_end_word,
  ['N'] = prev_search,
  ['n'] = next_search,
  ['[s'] = prev_misspell,
  [']s'] = next_misspell,
  ['[z'] = prev_open_fold,
  [']z'] = next_open_fold,
  ['zk'] = prev_fold,
  ['zj'] = next_fold,
  ['<c-n>'] = '<nop>',
  ['<c-p>'] = '<nop>',
  ['<leader>sc'] = function()
    vim.wo.spell = not vim.wo.spell
    local msg = vim.wo.spell and 'Spell check enabled' or 'Spell check disabled'
    vim.notify(msg, nil, { title = 'Settings' })
  end,
  ['<leader>ts'] = function()
    local buf = vim.api.nvim_get_current_buf()
    local status = vim.treesitter.highlighter.active[buf] ~= nil
    if status then
      vim.treesitter.stop()
      vim.notify('Treesitter stopped', nil, { title = 'Treesitter' })
    else
      local ok = pcall(vim.treesitter.start)
      if not ok then
        vim.notify('Treesitter failed to start', vim.log.levels.WARN, { title = 'Treesitter' })
      else
        vim.notify('Treesitter started successfully', nil, { title = 'Treesitter' })
      end
    end
  end,
  ['<leader>i'] = function()
    if vim.lsp.inlay_hint.is_enabled() then
      vim.notify('Inlay hints disabled', nil, { title = 'LSP' })
    else
      vim.notify('Inlay hints enabled', nil, { title = 'LSP' })
    end
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end,
}

for k, v in pairs(c.keys) do
  if not v or not operation[k] then goto continue end
  map(v.mode, v.key, operation[k], convert(v))
  ::continue::
end
