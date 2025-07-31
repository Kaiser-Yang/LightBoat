local util = require('lightboat.util')
local M = {}
local config = require('lightboat.config')
local c

local operation = {
  ['<leader>1'] = function() require('bufferline').go_to(1, true) end,
  ['<leader>2'] = function() require('bufferline').go_to(2, true) end,
  ['<leader>3'] = function() require('bufferline').go_to(3, true) end,
  ['<leader>4'] = function() require('bufferline').go_to(4, true) end,
  ['<leader>5'] = function() require('bufferline').go_to(5, true) end,
  ['<leader>6'] = function() require('bufferline').go_to(6, true) end,
  ['<leader>7'] = function() require('bufferline').go_to(7, true) end,
  ['<leader>8'] = function() require('bufferline').go_to(8, true) end,
  ['<leader>9'] = function() require('bufferline').go_to(9, true) end,
  ['<leader>0'] = function() require('bufferline').go_to(10, true) end,
  ['gb'] = '<cmd>BufferLinePick<CR>',
  ['<m-h>'] = '<cmd>BufferLineCyclePrev<cr>',
  ['<m-l>'] = '<cmd>BufferLineCycleNext<cr>',
}
local spec = {
  'akinsho/bufferline.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  version = '*',
  event = 'VeryLazy',
  opts = {
    options = {
      numbers = function(opts)
        local state = require('bufferline.state')
        for i, buf in ipairs(state.components) do
          if buf.id == opts.id then return tostring(i) end
        end
        return tostring(opts.ordinal)
      end,
      offsets = {
        { filetype = 'neo-tree', text = 'NeoTree', highlight = 'Directory', text_align = 'left' },
        { filetype = 'dapui_watches', text = 'DAP', highlight = 'Error', text_align = 'left' },
      },
      diagnostics = 'nvim_lsp',
      diagnostics_indicator = function(_, _, diagnostics_dict, _)
        local s = ' '
        for e, n in pairs(diagnostics_dict) do
          local sym = e == 'error' and ' ' or (e == 'warning' and ' ' or '')
          s = s .. n .. sym
        end
        return s
      end,
      sort_by = 'insert_after_current',
    },
  },
  keys = {},
}

function M.clear()
  spec.keys = {}
  c = nil
end

function M.spec() return spec end

M.setup = util.setup_check_wrap('lightboat.plugin.ui.buffer_line', function()
  c = config.get().buffer_line
  if not c.enabled then return nil end
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
