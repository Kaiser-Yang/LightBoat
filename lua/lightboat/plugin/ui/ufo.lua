local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local group
local M = {}
local operation = {
  K = function()
    if require('ufo').peekFoldedLinesUnderCursor() then return end
    vim.lsp.buf.hover()
  end,
}
-- PERF:
-- Large memory usage when using ufo with large files
-- And disabling ufo can not release the memory
-- https://github.com/kevinhwang91/nvim-ufo/issues/311
local spec = {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },
  lazy = false,
  keys = {},
  opts = {
    open_fold_hl_timeout = 0, -- disable highlighting when opening folds
    fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
      local newVirtText = {}
      local suffix = (' 󰁂 %d '):format(endLnum - lnum)
      local sufWidth = vim.fn.strdisplaywidth(suffix)
      local targetWidth = width - sufWidth
      local curWidth = 0
      for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
          table.insert(newVirtText, chunk)
        else
          chunkText = truncate(chunkText, targetWidth - curWidth)
          local hlGroup = chunk[2]
          table.insert(newVirtText, { chunkText, hlGroup })
          chunkWidth = vim.fn.strdisplaywidth(chunkText)
          -- str width returned from truncate() may less than 2nd argument, need padding
          if curWidth + chunkWidth < targetWidth then
            suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
          end
          break
        end
        curWidth = curWidth + chunkWidth
      end
      table.insert(newVirtText, { suffix, 'MoreMsg' })
      return newVirtText
    end,
    provider_selector = function(buf)
      if require('lightboat.extra.big_file').is_big_file(buf) then return '' end
      return { 'lsp', 'indent' }
    end,
  },
}

function M.clear()
  spec.keys = {}
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  c = nil
end

function M.spec() return spec end

M.setup = util.setup_check_wrap('lightboat.plugin.ui.ufo', function()
  c = config.get().ufo
  if not c.enabled then return nil end
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  group = vim.api.nvim_create_augroup('LightBoatUfo', {})
  vim.api.nvim_create_autocmd('User', {
    pattern = 'BigFileDetector',
    group = group,
    callback = function(ev)
      if not ev.data then return end
      local ok, ufo = pcall(require, 'ufo')
      if not ok then return end
      ufo.detach(ev.buf)
    end,
  })
  return spec
end, M.clear)

return M
