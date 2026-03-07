local util = require('lightboat.util')
local rep_move = require('lightboat.extra.rep_move')
local prev_end_word, next_end_word = rep_move.make('ge', 'e')
local prev_big_end_word, next_big_end_word = rep_move.make('gE', 'E')
local prev_fold, next_fold = rep_move.make('zk', 'zj')
local prev_open_fold, next_open_fold = rep_move.make('[z', ']z')

local operation = {
  ['ge'] = prev_end_word,
  ['e'] = next_end_word,
  ['gE'] = prev_big_end_word,
  ['E'] = next_big_end_word,
  ['[z'] = prev_open_fold,
  [']z'] = next_open_fold,
  ['zk'] = prev_fold,
  ['zj'] = next_fold,
}
