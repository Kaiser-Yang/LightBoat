local M = {}

local enabled = function(name) return vim.b[name] == true or vim.b[name] == nil and vim.g[name] == true end

local setup_autocmd = function()
  local group = vim.api.nvim_create_augroup('LightBoatAutoCmd', { clear = true })
  vim.api.nvim_create_autocmd('ModeChanged', {
    group = group,
    callback = function()
      if not enabled('nohlsearch_auto_run') then return end
      local cmdtype = vim.fn.getcmdtype()
      if
        vim.tbl_contains({ 'i', 'ic', 'ix', 'R', 'Rc', 'Rx', 'Rv', 'Rvc', 'Rvx' }, vim.api.nvim_get_mode().mode)
        or cmdtype ~= '' and cmdtype ~= '/' and cmdtype ~= '?'
      then
        vim.schedule(function() vim.cmd('nohlsearch') end)
      end
    end,
  })
  -- INFO: this should be checked when blink.cmp updates
  -- Copied from blink.cmp
  local capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
          commitCharactersSupport = false, -- todo:
          documentationFormat = { 'markdown', 'plaintext' },
          deprecatedSupport = true,
          preselectSupport = false, -- todo:
          tagSupport = { valueSet = { 1 } }, -- deprecated
          insertReplaceSupport = true, -- todo:
          resolveSupport = {
            properties = {
              'documentation',
              'detail',
              'additionalTextEdits',
              'command',
              'data',
              -- todo: support more properties? should test if it improves latency
            },
          },
          insertTextModeSupport = {
            -- todo: support adjustIndentation
            valueSet = { 1 }, -- asIs
          },
          labelDetailsSupport = true,
        },
        completionList = {
          itemDefaults = {
            'commitCharacters',
            'editRange',
            'insertTextFormat',
            'insertTextMode',
            'data',
          },
        },

        contextSupport = true,
        insertTextMode = 1, -- asIs
      },
    },
  }
  vim.api.nvim_create_autocmd('User', {
    pattern = 'VeryLazy',
    group = group,
    callback = function()
      -- Make sure nvim-lspconfig is loaded if installed
      pcall(require, 'nvim-lspconfig')
      vim.lsp.config('*', vim.tbl_deep_extend('force', capabilities, vim.lsp.config['*'].capabilities or {}))
      local lsp_path = vim.fn.stdpath('config')
      if lsp_path:sub(-1) ~= '/' then lsp_path = lsp_path .. '/' end
      lsp_path = lsp_path .. 'after/lsp'
      local lsp_files = vim.fn.glob(lsp_path .. '/*.lua', true, true)
      vim.lsp.enable(vim.tbl_map(function(file) return vim.fn.fnamemodify(file, ':t:r') end, lsp_files))
    end,
  })
  --- @type table<string, boolean>
  local loaded = {}
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'LazyLoad',
    callback = function(args)
      loaded[args.data] = true
      if loaded['nvim-treesitter'] then
        local installed = require('nvim-treesitter').get_installed()
        local not_installed = vim.tbl_filter(
          function(lang) return not vim.tbl_contains(installed, lang) end,
          vim.g.lightboat_opt.treesitter_ensure_installed
        )
        if #not_installed > 0 then require('nvim-treesitter').install(not_installed) end
      end
    end,
  })
  local guessed = {}
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = group,
    callback = function(args)
      if not enabled('conform_on_save') then return end
      require('conform').format({ bufnr = args.buf }, function(err)
        if err then vim.schedule(function() vim.notify('Format failed: ' .. err, vim.log.levels.ERROR) end) end
        if not err and not guessed[args.buf] and enabled('conform_on_save_reguess_indent') then
          guessed[args.buf] = true
          require('guess-indent').set_from_buffer(args.buf, true, true)
        end
      end)
    end,
  })
  vim.api.nvim_create_autocmd('TextYankPost', {
    group = group,
    callback = function()
      if not enabled('highlight_on_yank') then return end
      local limit = vim.b.highlight_on_yank_limit or vim.g.highlight_on_yank_limit
      local timeout = vim.b.highlight_on_yank_duration or vim.g.highlight_on_yank_duration
      if vim.v.event.regcontents and (not limit or #vim.v.event.regcontents <= limit) then
        vim.hl.on_yank({ timeout = timeout })
      end
    end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function()
      local c = require('lightboat.condition')
      local tac = c():treesitter_available()
      if not tac() then return end
      local thac = c():treesitter_highlight_available()
      if thac() and enabled('treesitter_highlight_auto_start') then vim.treesitter.start() end
      local tfac = c():treesitter_foldexpr_available()
      if tfac() and enabled('treesitter_foldexpr_auto_set') then
        vim.wo[0][0].foldenable = true
        vim.wo[0][0].foldmethod = 'expr'
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      end
      local tiac = c():treesitter_indentexpr_available()
      if tiac() and enabled('treesitter_indentexpr_auto_set') then
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end,
  })
  if enabled('conform_formatexpr_auto_set') then vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" end
  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function()
      if not enabled('conform_formatexpr_auto_set') then return end
      vim.bo.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  })
end

M.setup = function()
  require('lightboat.extra').setup()
  local util = require('lightboat.util')
  util.network.check()
  util.git.detect()
  util.start_to_detect_color()
  setup_autocmd()
end

return M
