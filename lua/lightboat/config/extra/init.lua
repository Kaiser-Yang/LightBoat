--- @class LightBoat.Opts.Extra
local M = {
  root_markers = { '.git', '.nvim', '.vscode' },
  markdown_fts = { 'markdown', 'gitcommit', 'text', 'Avante', 'AvanteInput' },
  big_file = require('lightboat.config.extra.big_file'),
  fold_sign = require('lightboat.config.extra.fold_sign'),
  line_wise = require('lightboat.config.extra.line_wise'),
  rep_move = require('lightboat.config.extra.rep_move'),
  command = require('lightboat.config.extra.command'),
}

return M
