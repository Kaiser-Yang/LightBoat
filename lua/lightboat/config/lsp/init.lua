--- @class LightBoat.Opts.Extra.Lsp
local M = {
  enabled = true,
  config = {
    bashls = {},
    clangd = {},
    eslint = {},
    jsonls = {},
    lemminx = {},
    lua_ls = require('lightboat.config.lsp.lua_ls'),
    neocmake = {},
    pyright = {},
    tailwindcss = {},
    ts_ls = require('lightboat.config.lsp.ts_ls'),
    vue_ls = require('lightboat.config.lsp.vue_ls'),
    yamlls = {},
    markdown_oxide = {},
  },
  keys = {
    ['ga'] = { key = 'ga', desc = 'Code action', mode = { 'v', 'n' } },
    ['gd'] = { key = 'gd', desc = 'Go to definition' },
    ['gt'] = { key = 'gt', desc = 'Go to type definition' },
    ['gi'] = { key = 'gi', desc = 'Go to implementations' },
    ['grr'] = { key = 'grr', desc = 'Go references' },
    ['gro'] = { key = 'gro', desc = 'Outgoing calls' },
    ['gri'] = { key = 'gri', desc = 'Incoming calls' },
    ['grn'] = { key = 'grn', desc = 'Rename' },
    [']d'] = { key = ']d', desc = 'Next diagnostic', mode = { 'n', 'x', 'o' }, expr = true },
    ['[d'] = { key = '[d', desc = 'Prev diagnostic', mode = { 'n', 'x', 'o' }, expr = true },
  },
}

return M
