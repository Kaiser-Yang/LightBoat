local util = require('lightboat.util')

--- @class LightBoat.Opts
local default_opts = {
  debug = false,
  autocmd = require('lightboat.config.autocmd'),
  keymap = require('lightboat.config.keymap'),
  blink_cmp = require('lightboat.config.blink_cmp'),
  buffer_line = require('lightboat.config.buffer_line'),
  comment = require('lightboat.config.comment'),
  conflict = require('lightboat.config.conflict'),
  conform = require('lightboat.config.conform'),
  dap = require('lightboat.config.dap'),
  extra = require('lightboat.config.extra'),
  flash = require('lightboat.config.flash'),
  insteresting_words = require('lightboat.config.interesting_words'),
  lsp = require('lightboat.config.lsp'),
  mason = require('lightboat.config.mason'),
  neo_tree = require('lightboat.config.neo_tree'),
  noice = require('lightboat.config.noice'),
  pair = require('lightboat.config.pair'),
  resizer = require('lightboat.config.resizer'),
  sign = require('lightboat.config.sign'),
  snack = require('lightboat.config.snack'),
  todo = require('lightboat.config.todo'),
  treesitter = require('lightboat.config.treesitter'),
  which_key = require('lightboat.config.which_key'),
  yanky = require('lightboat.config.yanky'),
}

local function lower_brackets(s)
  return s:gsub('%b<>', function(m) return '<' .. m:sub(2, -2):lower() .. '>' end)
end

local function normalize_keys(t)
  for k, v in pairs(t) do
    if k == 'keys' and type(v) == 'table' then
      for key, entry in pairs(v) do
        assert(entry.key and type(entry.key) == 'string')
        local new_key = lower_brackets(key)
        entry.key = lower_brackets(entry.key)
        if new_key ~= key then
          v[new_key] = v[key]
          v[key] = nil
        end
      end
    elseif type(v) == 'table' then
      v = normalize_keys(v)
    end
  end
  return t
end

local M = {}

function M.clear() vim.g.lightboat_opts = vim.deepcopy(default_opts) end

M.setup = util.setup_check_wrap('lightboat.config', function()
  vim.g.lightboat_opts = vim.tbl_deep_extend('force', default_opts, vim.g.lightboat_opts or {})
  vim.g.lightboat_opts = normalize_keys(vim.g.lightboat_opts)
end, M.clear)

--- @return LightBoat.Opts
function M.get() return vim.g.lightboat_opts end

return M
