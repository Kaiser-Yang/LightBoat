--- @class LightBoat.Opts.Lsp
local M = {
  enabled = true,
  keys = {
    ['gd'] = { key = 'gd', desc = 'Go to definition', buffer = true },
    ['grI'] = { key = 'grI', desc = 'Go to implementations', buffer = true },
    ['grt'] = { key = 'grt', desc = 'Go to type definition', buffer = true },
    ['gra'] = { key = 'gra', desc = 'Code action', mode = { 'v', 'n' }, buffer = true },
    ['grr'] = { key = 'grr', desc = 'Go references', buffer = true },
    ['gro'] = { key = 'gro', desc = 'Outgoing calls', buffer = true },
    ['gri'] = { key = 'gri', desc = 'Incoming calls', buffer = true },
    ['grn'] = { key = 'grn', desc = 'Rename', buffer = true },
    [']d'] = { key = ']d', desc = 'Next diagnostic', mode = { 'n', 'x', 'o' }, expr = true, buffer = true },
    ['[d'] = { key = '[d', desc = 'Prev diagnostic', mode = { 'n', 'x', 'o' }, expr = true, buffer = true },
  },
}

return M
