local c = require('lightboat.config').get().autocmd
if not c.enabled then return end

local group = vim.api.nvim_create_augroup('LightBoatBuiltin', {})
local util = require('lightboat.util')
local search = util.search
if c.auto_disable_hlsearch then
  vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
    group = group,
    callback = function()
      local mode = vim.fn.mode('1')
      if mode ~= 'n' then return end -- Only handle normal mode
      if not search.cursor_in_match() then vim.schedule(function() vim.cmd('nohlsearch') end) end
    end,
  })
end
if vim.g.vscode then return end

vim.api.nvim_create_autocmd('BufEnter', {
  callback = function()
    if vim.bo.filetype:match('^dap%-repl') then vim.cmd('stopinsert') end
  end,
})
