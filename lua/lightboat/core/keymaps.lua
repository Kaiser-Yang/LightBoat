local util = require('lightboat.util')
local map = util.key.set
local feedkeys = util.key.feedkeys
local rep_move = require('lightboat.extras.rep_move')
local prev_word, next_word = rep_move.make('b', 'w')
local prev_big_word, next_big_word = rep_move.make('B', 'W')
local prev_end_word, next_end_word = rep_move.make('ge', 'e')
local prev_big_end_word, next_big_end_word = rep_move.make('gE', 'E')
local prev_search, next_search = rep_move.make('N', 'n')
local prev_misspell, next_misspell = rep_move.make('[s', ']s')
local prev_fold, next_fold = rep_move.make('zk', 'zj')
local prev_open_fold, next_open_fold = rep_move.make('[z', ']z')

-- Copy, cut, paste, and select all
map('n', '<leader>ay', function()
    -- HACK:
    -- highlight when the file is small?
    vim.fn.setreg('+', vim.api.nvim_buf_get_lines(0, 0, -1, false), 'l')
    local line_count = vim.api.nvim_buf_line_count(0)
    vim.notify(string.format('Yanked %d lines to + register', line_count), nil, { title = 'Yank' })
end, { desc = 'Yank around file to + reg' })
map({ 'n', 'x' }, '<m-x>', '"+d', { desc = 'Cut to + reg' })
map({ 'n', 'x', 'i' }, '<m-a>', function()
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
end, { desc = 'Select all' })

-- Quick operations
map('i', '<c-u>', function()
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], #line:match('^%s*') })
    vim.api.nvim_set_current_line(line:match('^%s*') .. line:sub(cursor_col + 1))
end, { desc = 'Delete to start of line' })
map('i', '<c-w>', function()
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    local line_len = #vim.api.nvim_get_current_line()
    local res = '<c-o><cmd>normal '
    if cursor_col == line_len then
        res = res .. 'vlbc<cr>'
    else
        res = res .. 'hvbx<cr>'
    end
    feedkeys(res, 'n')
end, { desc = 'Delete one word backwards' })
map({ 'x', 'i', 'c' }, '<c-a>', function()
    local res
    if vim.fn.mode() == 'c' then
        res = '<home>'
    elseif vim.fn.mode() ~= 'n' then
        res = '<c-o>^'
    else
        res = '^'
    end
    return res
end, { desc = 'Move cursor to start of line' })
map({ 'x', 'i', 'c' }, '<c-e>', '<end>', { desc = 'Move cursor to end of line' })

-- Windows related
map(
    'n',
    '<leader>l',
    '<cmd>set splitright<cr><cmd>vsplit<cr><cmd>set nosplitright<cr>',
    { desc = 'Split vertically' }
)
map(
    'n',
    '<leader>j',
    '<cmd>set splitbelow<cr><cmd>split<cr><cmd>set nosplitbelow<cr>',
    { desc = 'Split below' }
)
map('n', '<leader>h', '<cmd>vsplit<cr>', { desc = 'Split vertically' })
map('n', '<leader>k', '<cmd>split<cr>', { desc = 'Split above' })
map('n', '=', '<cmd>wincmd =<cr>', { desc = 'Equalize windows' })
map('n', '<c-h>', '<c-w>h', { desc = 'Cursor left' })
map('n', '<c-j>', '<c-w>j', { desc = 'Cursor down' })
map('n', '<c-k>', '<c-w>k', { desc = 'Cursor up' })
map('n', '<c-l>', '<c-w>l', { desc = 'Cursor right' })
map('n', '<leader>T', '<cmd>tab split<cr>', { desc = 'Move current window to a new tabpage' })

-- Tabsize related
map('n', '<leader>t2', function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
end, { desc = 'Set tab with 2 spaces' })
map('n', '<leader>t4', function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
end, { desc = 'Set tab with 4 spaces' })
map('n', '<leader>t8', function()
    vim.bo.tabstop = 8
    vim.bo.shiftwidth = 8
end, { desc = 'Set tab with 8 spaces' })
map('n', '<leader>tt', function()
    if vim.bo.expandtab then
        vim.bo.expandtab = false
        vim.notify('Expandtab disabled', nil, { title = 'Settings' })
    else
        vim.bo.expandtab = true
        vim.notify('Expandtab enabled', nil, { title = 'Settings' })
    end
end, { desc = 'Toggle expandtab' })

-- Motion
map({ 'n', 'o', 'x' }, 'b', prev_word, { desc = 'Previous word' })
map({ 'n', 'o', 'x' }, 'w', next_word, { desc = 'Next word' })
map({ 'n', 'o', 'x' }, 'B', prev_big_word, { desc = 'Previous big word' })
map({ 'n', 'o', 'x' }, 'W', next_big_word, { desc = 'Next big word' })
map({ 'n', 'o', 'x' }, 'ge', prev_end_word, { desc = 'Previous end word' })
map({ 'n', 'o', 'x' }, 'e', next_end_word, { desc = 'Next end word' })
map({ 'n', 'o', 'x' }, 'gE', prev_big_end_word, { desc = 'Previous big end word' })
map({ 'n', 'o', 'x' }, 'E', next_big_end_word, { desc = 'Next big end word' })
map({ 'n', 'o', 'x' }, 'N', prev_search, { desc = 'Previous search pattern' })
map({ 'n', 'o', 'x' }, 'n', next_search, { desc = 'Next search pattern' })
map({ 'n', 'o', 'x' }, '[s', prev_misspell, { desc = 'Previous misspelled word' })
map({ 'n', 'o', 'x' }, ']s', next_misspell, { desc = 'Next misspelled word' })
map({ 'n', 'o', 'x' }, '[z', prev_open_fold, { desc = 'Move to start of current fold' })
map({ 'n', 'o', 'x' }, ']z', next_open_fold, { desc = 'Move to end of current fold' })
map({ 'n', 'o', 'x' }, 'zk', prev_fold, { desc = 'Move upwards to the end of the previous fold' })
map({ 'n', 'o', 'x' }, 'zj', next_fold, { desc = 'Move downwards to the start of the next fold' })

-- Others
map({ 'i' }, '<c-n>', '<nop>')
map({ 'i' }, '<c-p>', '<nop>')
map('n', '<leader>sc', function()
    if vim.o.spell then
        vim.notify('Spell check disabled', nil, { title = 'Spell Check' })
    else
        vim.notify('Spell check enabled', nil, { title = 'Spell Check' })
    end
    vim.cmd('set spell!')
end, { desc = 'Toggle spell check' })
