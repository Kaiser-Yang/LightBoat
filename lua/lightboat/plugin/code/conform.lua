local M = {}
local util = require('lightboat.util')
local config = require('lightboat.config')
local c

local operation = {
  ['<leader>f'] = function()
    require('conform').format({ async = true, lsp_format = 'fallback' }, function()
      if vim.api.nvim_get_mode().mode ~= 'n' then util.key.feedkeys('<esc>', 'n') end
    end)
  end,
}

local spec = {
  'stevearc/conform.nvim',
  cond = not vim.g.vscode,
  opts = {
    formatters_by_ft = {
      c = { 'clang-format' },
      cpp = { 'clang-format' },
      go = { 'goimports' },
      python = { 'autopep8' },
      java = { 'google-java-format' },
      markdown = { 'prettier' },
      lua = { 'stylua' },
      vue = { 'prettier' },
      typescript = { 'prettier' },
      javascript = { 'prettier' },
      css = { 'prettier' },
      bzl = { 'buildifier' },
      bazelrc = { 'buildifier' },
    },
  },
  cmd = { 'ConformInfo' },
  keys = {},
}

function M.spec() return spec end

function M.clear()
  spec.keys = {}
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.code.conform', function()
  c = config.get().conform
  spec.enabled = c.enabled
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
