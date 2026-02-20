local util = require('lightboat.util')
local config = require('lightboat.config')
local big_file = require('lightboat.extra.big_file')
local rep_move = require('lightboat.extra.rep_move')
local map = util.key.set
local c
local group
local feedkeys = util.key.feedkeys
local prev_diagnostic, next_diagnostic = rep_move.make(
  function() feedkeys('<cmd>Lspsaga diagnostic_jump_prev<cr>', 'nt') end,
  function() feedkeys('<cmd>Lspsaga diagnostic_jump_next<cr>', 'nt') end
)

--- @param bufnr integer
--- @param lsp_config vim.lsp.Config
local function start_config(bufnr, lsp_config)
  return vim.lsp.start(lsp_config, {
    bufnr = bufnr,
    reuse_client = lsp_config.reuse_client,
    _root_markers = lsp_config.root_markers,
  })
end

local M = {}

local operation = {
  ['gd'] = '<cmd>Lspsaga goto_definition<cr>',
  ['grI'] = '<cmd>Lspsaga finder imp<cr>',
  ['grt'] = '<cmd>Lspsaga goto_type_definition<cr>',
  ['gra'] = '<cmd>Lspsaga code_action<cr>',
  ['grr'] = '<cmd>Lspsaga finder ref<cr>',
  ['gro'] = '<cmd>Lspsaga outgoing_calls<cr>',
  ['gri'] = '<cmd>Lspsaga incoming_calls<cr>',
  ['grn'] = '<cmd>Lspsaga rename mode=n<cr>',
  [']d'] = next_diagnostic,
  ['[d'] = prev_diagnostic,
}
local spec = {
  {
    'nvimdev/lspsaga.nvim',
    cond = not vim.g.vscode,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'LspAttach',
    opts = {
      callhierarchy = { keys = { edit = { '<cr>' }, quit = { 'q', '<esc>' } } },
      definition = { keys = { quit = { 'q', '<esc>' } } },
      code_action = { keys = { quit = { 'q', '<esc>' }, exec = '<cr>' } },
      diagnostic = { keys = { exec_action = '<cr>', quit = { 'q', '<esc>' }, quit_in_show = { 'q', '<esc>' } } },
      finder = {
        keys = {
          quit = { 'q', '<esc>' },
          shutter = { '<m-w>' },
          split = { 's', '<c-s>', '<leader>j', '<leader>k' },
          vsplit = { 'v', '<c-v>', '<leader>l', '<leader>h' },
          toggle_or_open = { 'o', '<cr>' },
        },
      },
      rename = { in_select = false, auto_save = true, keys = { quit = { '<c-c>' } } },
      lightbulb = { enable = false },
    },
    config = function(_, opts)
      local ok, lsp_saga = pcall(require, 'catppuccin.groups.integrations.lsp_saga')
      if ok then opts.ui = { kind = lsp_saga.custom_kind() } end
      require('lspsaga').setup(opts)
    end,
    keys = {},
  },
}

function M.spec() return spec end

function M.clear()
  assert(spec[2][1] == 'nvimdev/lspsaga.nvim')
  spec[2].keys = {}
  c = nil
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
end

M.setup = util.setup_check_wrap('lightboat.plugin.code.lsp', function()
  if vim.g.vscode then return spec end
  c = config.get()
  for _, s in ipairs(spec) do
    s.enabled = c.lsp.enabled
  end
  assert(spec[2][1] == 'nvimdev/lspsaga.nvim')
  group = vim.api.nvim_create_augroup('LightBoatLsp', {})
  for name, lsp_config in pairs(c.lsp.config) do
    if not lsp_config then goto continue end
    vim.lsp._enabled_configs[name] = {}
    vim.lsp.config(name, vim.tbl_extend('force', vim.lsp.config[name] or {}, lsp_config))
    ::continue::
  end
  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function() util.key.set_keys(operation, c.lsp.keys) end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'sagarename',
    callback = function()
      map({ 'i', 'n' }, '<esc>', function()
        if vim.api.nvim_get_mode().mode == 'i' then
          feedkeys('<esc>', 'n')
        else
          feedkeys('<c-c>', 'm')
        end
      end, { buffer = true })
    end,
  })
  -- PERF:
  -- https://github.com/neovim/neovim/issues/35361
  -- Memory did not goes down for large files???
  return spec
end, M.clear)

return M
