--- @class LightBoat.Opts.Lsp
local M = {
  enabled = true,
  config = {
    bashls = {},
    gopls = {},
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
    ['gd'] = { key = 'gd', desc = 'Go to definition' },
    ['gt'] = { key = 'gt', desc = 'Go to type definition' },
    ['gi'] = { key = 'gi', desc = 'Go to implementations' },
    ['gra'] = { key = 'gra', desc = 'Code action', mode = { 'v', 'n' } },
    ['grr'] = { key = 'grr', desc = 'Go references' },
    ['gro'] = { key = 'gro', desc = 'Outgoing calls' },
    ['gri'] = { key = 'gri', desc = 'Incoming calls' },
    ['grn'] = { key = 'grn', desc = 'Rename' },
    [']d'] = { key = ']d', desc = 'Next diagnostic', mode = { 'n', 'x', 'o' }, expr = true },
    ['[d'] = { key = '[d', desc = 'Prev diagnostic', mode = { 'n', 'x', 'o' }, expr = true },
  },
}

return M
