--- @class LightBoat.Opts.Extra.Dap
local M = {
  enabled = true,
  adapters = require('lightboat.config.dap.adapters'),
  configurations = require('lightboat.config.dap.configurations'),
  keys = {
    ['<leader>du'] = { key = '<leader>du', desc = 'Toggle debug ui' },
    ['<leader>b'] = { key = '<leader>b', desc = 'Toggle breakpoint' },
    ['<leader>B'] = { key = '<leader>B', desc = 'Set condition breakpoint' },
    ['<leader>df'] = { key = '<leader>df', desc = 'Debug float element' },
    ['<leader>de'] = { key = '<leader>de', desc = 'Debug eval expression' },
    ['<leader>dl'] = { key = '<leader>dl', desc = 'Set log point for current line' },
    ['<f4>'] = { key = '<f4>', desc = 'Debug terminate' },
    ['<f5>'] = { key = '<f5>', desc = 'Debug continue or run last' },
    ['<f6>'] = { key = '<f6>', desc = 'Debug restart' },
    ['<f9>'] = { key = '<f9>', desc = 'Debug back' },
    ['<f10>'] = { key = '<f10>', desc = 'Debug next' },
    ['<f11>'] = { key = '<f11>', desc = 'Debug step into' },
    ['<f12>'] = { key = '<f12>', desc = 'Debug step out' },
  },
}

return M
