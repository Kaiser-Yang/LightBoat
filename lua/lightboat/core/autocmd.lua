local c = require('lightboat.config').get().autocmd
if not c.enabled then return end

local group = vim.api.nvim_create_augroup('LightBoatBuiltin', {})
local util = require('lightboat.util')
local search = util.search
if c.auto_disable_hlsearch then
  vim.api.nvim_create_autocmd('ModeChanged', {
    group = group,
    pattern = 'n:[^n]',
    callback = function()
      vim.schedule(function() vim.cmd('nohlsearch') end)
    end,
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
    group = group,
    callback = function()
      local mode = vim.fn.mode('1')
      if mode ~= 'n' then return end -- Only handle normal mode
      if not search.cursor_in_match() then vim.schedule(function() vim.cmd('nohlsearch') end) end
    end,
  })
end
if c.gitcommit_colorcolumn then
  -- Update the colorcolumn when entering a gitcommit buffer
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'gitcommit',
    callback = function() vim.wo.colorcolumn = c.gitcommit_colorcolumn end,
  })
end
if c.formatoptions then
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function() vim.bo.formatoptions = 'crqn2lMj' end,
  })
end
