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
  ['ga'] = '<cmd>Lspsaga code_action<cr>',
  ['gd'] = '<cmd>Lspsaga goto_definition<cr>',
  ['gt'] = '<cmd>Lspsaga goto_type_definition<cr>',
  ['gi'] = '<cmd>Lspsaga finder imp<cr>',
  ['grr'] = '<cmd>Lspsaga finder ref<cr>',
  ['gro'] = '<cmd>Lspsaga outgoing_calls<cr>',
  ['gri'] = '<cmd>Lspsaga incoming_calls<cr>',
  ['grn'] = '<cmd>Lspsaga rename mode=n<cr>',
  [']d'] = next_diagnostic,
  ['[d'] = prev_diagnostic,
}
local spec = {
  { 'neovim/nvim-lspconfig' },
  {
    'nvimdev/lspsaga.nvim',
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
          shutter = { '<a-w>' },
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
  c = config.get()
  if not c.lsp.enabled then return nil end
  assert(spec[2][1] == 'nvimdev/lspsaga.nvim')
  spec[2].keys = util.key.get_lazy_keys(operation, c.lsp.keys)
  group = vim.api.nvim_create_augroup('LightBoatLsp', {})
  for name in pairs(c.lsp.config) do
    vim.lsp._enabled_configs[name] = {}
    vim.lsp.config[name] = vim.tbl_extend('force', vim.lsp.config[name] or {}, c.lsp.config[name] or {})
  end
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      -- PERF:
      -- Large files can cause performance issues with LSP.
      -- Therefore we disable LSP for large files.
      if big_file.is_big_file(bufnr) then
        vim.notify('LSP is disabled for this file due to its size.', vim.log.levels.WARN)
        return
      end
      if vim.bo[bufnr].buftype ~= '' then return end
      for name in pairs(vim.lsp._enabled_configs) do
        local lsp_config = vim.lsp.config[name]
        if
          lsp_config and (not lsp_config.filetypes or vim.tbl_contains(lsp_config.filetypes, vim.bo[bufnr].filetype))
        then
          -- Deepcopy config so chagnes done in the client
          -- do not propagate to the enabled config
          lsp_config = vim.deepcopy(lsp_config)
          lsp_config.capabilities = require('blink.cmp').get_lsp_capabilities(lsp_config.capabilities)
          if c.extra.root_markers and #c.extra.root_markers ~= 0 then
            lsp_config.root_markers = util.ensure_list(lsp_config)
            table.insert(lsp_config.root_markers, c.extra.root_markers)
          end
          if type(lsp_config.root_dir) == 'function' then
            ---@param root_dir string
            lsp_config.root_dir(bufnr, function(root_dir)
              lsp_config.root_dir = root_dir
              vim.schedule(function() start_config(bufnr, lsp_config) end)
            end)
          else
            start_config(bufnr, lsp_config)
          end
        end
      end
    end,
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
  return spec
end, M.clear)

return M
