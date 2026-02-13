local M = {}

local c = require('lightboat.condition')
--- @type table<string, boolean>
local loaded = {}
--- @type table<string, boolean>
local done = {}
local util = require('lightboat.util')

-- HACK:
-- This should be checked when blink.cmp updates
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
  local lc = c():plugin_available('nvim-lspconfig')
  vim.api.nvim_create_autocmd('User', {
    pattern = 'VeryLazy',
    group = group,
    callback = function()
      vim.lsp.config('*', vim.tbl_deep_extend('force', capabilities, vim.lsp.config['*'].capabilities or {}))
      if lc() and not loaded['nvim-lspconfig'] then require('lspconfig') end
      local lsp_path = vim.fn.stdpath('config')
      if lsp_path:sub(-1) ~= '/' then lsp_path = lsp_path .. '/' end
      lsp_path = lsp_path .. 'after/lsp'
      vim.uv.fs_scandir(lsp_path, function(err, fd)
        if err or not fd then
          vim.notify('Failed to scan LSP dir: ' .. tostring(err), vim.log.levels.ERROR, { title = 'LightBoat' })
          return
        end
        local servers = {}
        while true do
          local name, ftype = vim.uv.fs_scandir_next(fd)
          if not name then break end
          if ftype == 'file' and name:sub(-4) == '.lua' then table.insert(servers, name:sub(1, -5)) end
        end
        if #servers > 0 then vim.schedule(function() vim.lsp.enable(servers) end) end
      end)
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'LazyLoad',
    callback = function(args)
      loaded[args.data] = true
      if loaded['mason.nvim'] and not done['nvim.mason'] and #vim.g.lightboat_opt.mason_ensure_installed > 0 then
        done['nvim.mason'] = true
        local mason_registry = require('mason-registry')
        local installed = mason_registry.get_installed_package_names()
        local not_installed = vim.tbl_filter(
          function(pack) return not vim.tbl_contains(installed, pack) end,
          vim.g.lightboat_opt.mason_ensure_installed
        )
        if #not_installed > 0 then
          for _, pack in ipairs(mason_registry.get_all_packages()) do
            if vim.tbl_contains(not_installed, pack.name) then pack:install() end
          end
        end
      end
      if
        loaded['nvim-treesitter']
        and not done['nvim-treesitter']
        and #vim.g.lightboat_opt.treesitter_ensure_installed > 0
      then
        done['nvim-treesitter'] = true
        local installed = require('nvim-treesitter').get_installed()
        local not_installed = vim.tbl_filter(
          function(lang) return not vim.tbl_contains(installed, lang) end,
          vim.g.lightboat_opt.treesitter_ensure_installed
        )
        if #not_installed > 0 then require('nvim-treesitter').install(not_installed) end
      end
      -- This plugin is not loaded by setup function, we must call init manually
      if loaded['nvim-treesitter-endwise'] and not done['nvim-treesitter-endwise'] then
        done['nvim-treesitter-endwise'] = true
        local endwise = require('nvim-treesitter-endwise')
        endwise.init()
        -- Attach manually, since the plugin is lazy loaded and won't be attached on InsertEnter
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
          if not endwise.is_supported(lang) then return end
          require('nvim-treesitter.endwise').attach(buf)
        end
      end
      if loaded['blink.cmp'] and not done['blink.cmp'] then
        done['blink.cmp'] = true
        local original = require('blink.cmp.completion.list').show
        require('blink.cmp.completion.list').show = function(ctx, items_by_source)
          local seen = {}
          local function filter(item)
            if seen[item.label] then return false end
            seen[item.label] = true
            return true
          end
          -- HACK:
          -- This is a hack, see https://github.com/saghen/blink.cmp/issues/1222#issuecomment-2891921393
          for id in vim.iter({ 'snippets', 'lsp', 'dictionary', 'buffer', 'ripgrep' }) do
            items_by_source[id] = items_by_source[id] and vim.iter(items_by_source[id]):filter(filter):totable()
          end
          return original(ctx, items_by_source)
        end
      end
    end,
  })
  local guessed = {}
  local gc = c():plugin_available('guess-indent.nvim')
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = group,
    callback = function(args)
      if not enabled('conform_on_save') then return end
      local buffer = args.buf
      require('conform').format({ bufnr = buffer }, function(err)
        if err then
          vim.schedule(function() vim.notify('Format failed: ' .. err, vim.log.levels.ERROR, { title = 'Conform' }) end)
        end
        if not err and not guessed[buffer] and enabled('conform_on_save_reguess_indent') and gc() then
          guessed[buffer] = true
          require('guess-indent').set_from_buffer(buffer, true, false)
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
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'BufRead', 'FileChangedShell' }, {
    group = group,
    callback = function(ev)
      if vim.b.big_file_status == nil then vim.b.big_file_status = false end
      local is_big = util.buffer.big()
      if is_big ~= vim.b.big_file_status then
        vim.b.big_file_status = is_big
        if type(vim.b.big_file_on_changed) == 'function' then
          vim.b.big_file_on_changed(ev.buf, is_big)
        elseif type(vim.g.big_file_on_changed) == 'function' then
          vim.g.big_file_on_changed(ev.buf, is_big)
        end
      end
    end,
  })
end

M.setup = function()
  util.git.detect()
  setup_autocmd()
  -- We use this code to make the fold sign at the end of the status column and clickable as usually
  local function fold_clickable(lnum) return vim.fn.foldlevel(lnum) > vim.fn.foldlevel(lnum - 1) end
  _G.get_statuscol = function() return '%s%l%=' .. (fold_clickable(vim.v.lnum) and '%C' or ' ') .. ' ' end
  vim.o.statuscolumn = '%!v:lua.get_statuscol()'
end

return M
