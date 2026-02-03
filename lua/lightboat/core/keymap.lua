local c = require('lightboat.config').get().keymap
if not c.enabled then return end
local util = require('lightboat.util')
local map = util.key.set
local del = util.key.del
local feedkeys = util.key.feedkeys
local rep_move = require('lightboat.extra.rep_move')
local prev_fold, next_fold = rep_move.make('zk', 'zj')
local prev_open_fold, next_open_fold = rep_move.make('[z', ']z')

-- if c.delete_default_commant then del({ 'n', 'o', 'x' }, 'gc') end
-- if c.delete_default_diagnostic_under_cursor then
-- del('n', '<c-w>d')
-- del('n', '<c-w><c-d>')
-- end

-- if c.disable_default_find_match_in_inserat then
--   map('i', '<c-p>', '<nop>')
--   map('i', '<c-n>', '<nop>')
-- end

local operation = {
  ['<m-x>'] = function()
    if vim.fn.mode('1') == 'no' then
      if vim.v.operator == 'd' and vim.v.register == '+' then
        return '<esc>' .. tostring(vim.v.count) .. util.extra.line_wise_key_wrap('"+dd', c.keys['<m-x>'].opts)()
      end
    else
      return '"+d'
    end
  end,
  -- TODO:
  -- do not use this to select all text in the buffer
  -- We should add an operator instead
  ['<m-a>'] = function()
    local res = 'gg0vG$'
    if vim.fn.mode('1') ~= 'n' then res = '<esc>' .. res end
    return res
  end,
  ['<m-d>'] = '<c-g>u<cmd>normal de<cr>',
  ['<m-p>'] = '<cmd>pu<cr>',
  ['<m-P>'] = '<cmd>pu!<cr>',
  ['<c-w>'] = function()
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    local cur_line = vim.api.nvim_get_current_line()
    local line_len = #cur_line
    local res = '<c-g>u<c-o><cmd>normal '
    local key = (c.keys['b'] and c.keys['b'].key or 'b')
    if cursor_col == line_len then
      if cursor_col == 0 then
        res = res .. 'v' .. key .. 'l' .. 'c<cr>'
      else
        res = res .. 'vl' .. key .. 'c<cr>'
      end
    else
      res = res .. 'hv' .. key .. 'x<cr>'
    end
    return res
  end,
  ['<c-a>'] = function()
    local res
    local mode = vim.fn.mode('1')
    if mode == 'c' then
      local ok, noice_config = pcall(require, 'noice.config')
      if not ok then return '<home>' end
      local format = noice_config.defaults().cmdline.format
      if not format then return '<home>' end
      local line = vim.fn.getcmdtype() .. vim.fn.getcmdline()
      local matched = nil
      for _, v in pairs(format) do
        local ps = type(v.pattern) == 'table' and v.pattern or { v.pattern }
        for _, p in ipairs(ps) do
          if p and type(p) == 'string' then
            local cur_matched = line:match(p)
            if not matched or cur_matched and #cur_matched > #matched then matched = cur_matched end
          end
        end
      end
      if matched then
        res = '<home>' .. string.rep('<right>', #matched - 1)
      else
        res = '<home>'
      end
    elseif mode == 'i' then
      res = '<c-o>^'
    else
      res = '^'
    end
    return res
  end,
  ['<c-e>'] = function()
    local res
    local mode = vim.fn.mode('1')
    if mode == 'c' then
      res = '<end>'
    elseif mode == 'i' then
      res = '<c-o>$'
    else
      res = '$'
    end
    return res
  end,
  ['<leader>l'] = '<cmd>set splitright<cr><cmd>vsplit<cr><cmd>set nosplitright<cr>',
  ['<leader>j'] = '<cmd>set splitbelow<cr><cmd>split<cr><cmd>set nosplitbelow<cr>',
  ['<leader>h'] = '<cmd>vsplit<cr>',
  ['<leader>k'] = '<cmd>split<cr>',
  ['<c-h>'] = '<c-w>h',
  ['<c-j>'] = '<c-w>j',
  ['<c-k>'] = function()
    if vim.fn.mode('1') == 'n' then
      return '<c-w>k'
    else
      util.key.feedkeys('<c-g>u', 'nt')
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
  ['<leader>sc'] = function()
    vim.wo.spell = not vim.wo.spell
    local msg = vim.wo.spell and 'Spell check enabled' or 'Spell check disabled'
    vim.notify(msg, nil, { title = 'Settings' })
  end,
  ['<leader>i'] = function()
    if vim.g.vscode then return end
    local status = not vim.lsp.inlay_hint.is_enabled()
    local msg = status and 'Inlay hints enabled' or 'Inlay hints disabled'
    vim.notify(msg, nil, { title = 'LSP' })
    vim.lsp.inlay_hint.enable(status)
  end,
  ['<leader>ts'] = function()
    local buf = vim.api.nvim_get_current_buf()
    local status = vim.treesitter.highlighter.active[buf] == nil
    local msg, level
    if status then
      local ok = pcall(vim.treesitter.start)
      if not ok then
        msg = 'Treesitter failed to start'
        level = vim.log.levels.WARN
      else
        msg = 'Treesitter started successfully'
      end
    else
      vim.treesitter.stop()
      msg = 'Treesitter stopped'
    end
    vim.notify(msg, level, { title = 'Treesitter' })
  end,
}
-- util.key.set_keys(operation, c.keys)

if vim.g.vscode then return end

-- local yanky_loaded
-- local function separator_wrap(keys)
--   assert(type(keys) == 'string', 'keys must be a string')
--   assert(#keys == 2, 'keys must be 2 characters long')
--   return function()
--     local res = '<esc>'
--     if keys:sub(1, 1) == 'y' then
--       if yanky_loaded == nil then
--         local ok, _ = pcall(require, 'yanky')
--         yanky_loaded = ok
--       end
--       res = res .. (yanky_loaded and '<plug>(YankyYank)' or 'y')
--     else
--       res = res .. keys:sub(1, 1)
--     end
--     vim.schedule(function() feedkeys(keys:sub(2, 2), 'n') end)
--     return res
--   end
-- end
-- for keys, value in pairs(c.separate_operator) do
--   if value then map('n', keys, separator_wrap(keys), { expr = true }) end
-- end
