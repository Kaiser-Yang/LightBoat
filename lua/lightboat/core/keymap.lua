local c = require('lightboat.config').get().keymap
if not c.enabled then return end
local util = require('lightboat.util')
local map = util.key.set
local del = util.key.del
local feedkeys = util.key.feedkeys
local convert = util.key.convert
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

if c.delete_default_commant then del({ 'n', 'o', 'x' }, 'gc') end
if c.delete_default_diagnostic_under_cursor then
  del('n', '<c-w>d')
  del('n', '<c-w><c-d>')
end
if c.separate_operator.ya then
  map('n', 'ya', function()
    vim.schedule(function() feedkeys('a', 'n') end)
    return '<esc>y'
  end, { expr = true })
end
if c.separate_operator.yi then
  map('n', 'yi', function()
    vim.schedule(function() feedkeys('i', 'n') end)
    return '<esc>y'
  end, { expr = true })
end
if c.separate_operator.ca then
  map('n', 'ca', function()
    vim.schedule(function() feedkeys('a', 'n') end)
    return '<esc>c'
  end, { expr = true })
end
if c.separate_operator.ci then
  map('n', 'ci', function()
    vim.schedule(function() feedkeys('i', 'n') end)
    return '<esc>c'
  end, { expr = true })
end
if c.separate_operator.da then
  map('n', 'da', function()
    vim.schedule(function() feedkeys('a', 'n') end)
    return '<esc>d'
  end, { expr = true })
end
if c.separate_operator.di then
  map('n', 'di', function()
    vim.schedule(function() feedkeys('i', 'n') end)
    return '<esc>d'
  end, { expr = true })
end

local operation = {
  ['<m-x>'] = '"+d',
  ['<m-a>'] = function()
    if Snacks then
      vim.g.snacks_animate_scroll = false
      vim.schedule(function() vim.g.snacks_animate_scroll = true end)
    end
    local res = 'gg0vG$'
    if vim.fn.mode('1') ~= 'n' then res = '<esc>' .. res end
    return res
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
      res = res .. 'vl' .. c.keys['b'].key .. 'c<cr>'
    else
      res = res .. 'hv' .. c.keys['b'].key .. 'x<cr>'
    end
    return res
  end,
  ['<c-a>'] = function()
    local res
    if vim.fn.mode('1') == 'c' then
      res = '<home>'
    elseif vim.fn.mode('1') ~= 'n' then
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
  ['<c-k>'] = function()
    if vim.fn.mode('1') == 'n' then
      return '<c-w>k'
    else
      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      vim.schedule(function() vim.api.nvim_set_current_line(vim.api.nvim_get_current_line():sub(1, cursor_col)) end)
    end
  end,
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
  ['<leader>i'] = function()
    if vim.lsp.inlay_hint.is_enabled() then
      vim.notify('Inlay hints disabled', nil, { title = 'LSP' })
    else
      vim.notify('Inlay hints enabled', nil, { title = 'LSP' })
    end
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
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
  ['<m-d>'] = '<c-g>u<cmd>normal de<cr>',
}

for k, v in pairs(c.keys) do
  if not v or not operation[k] then goto continue end
  map(v.mode, v.key, operation[k], convert(v))
  ::continue::
end
