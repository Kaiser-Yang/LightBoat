local M = {}

--- @type table<string, boolean>
_G.plugin_loaded = {}
--- @type table<string, boolean>
local done = {}
local util = require('lightboat.util')
local function get_prompt_text(prompt, default_prompt)
  local prompt_text = prompt or default_prompt
  if prompt_text:sub(-1) == ':' then prompt_text = '[' .. prompt_text:sub(1, -2) .. ']' end
  return prompt_text
end
local function override_ui_select()
  local Menu = require('nui.menu')
  local event = require('nui.utils.autocmd').event
  local UISelect = Menu:extend('UISelect')

  function UISelect:init(items, opts, on_done)
    local border_top_text = get_prompt_text(opts.prompt, '[Select Item]')
    local kind = opts.kind or 'unknown'
    local format_item = opts.format_item or function(item) return tostring(item.__raw_item or item) end

    local popup_options = {
      relative = 'editor',
      position = '50%',
      border = { style = 'rounded', text = { top = border_top_text, top_align = 'left' } },
      win_options = { winhighlight = 'NormalFloat:Normal,FloatBorder:Normal' },
      zindex = 999,
    }

    if kind == 'codeaction' then
      -- change position for codeaction selection
      popup_options.relative = 'cursor'
      popup_options.position = { row = 2, col = 0 }
    end

    local max_width = popup_options.relative == 'editor' and vim.o.columns - 4 or vim.api.nvim_win_get_width(0) - 4
    local max_height = popup_options.relative == 'editor' and math.floor(vim.o.lines * 80 / 100)
      or vim.api.nvim_win_get_height(0)

    local menu_items = {}
    for index, item in ipairs(items) do
      local item_text = string.sub(format_item(item), 0, max_width)
      if not item_text:match('%d+%. ') then item_text = string.format('%d. %s', index, item_text):sub(0, max_width) end
      if type(item) ~= 'table' then item = { __raw_item = item } end
      item.index = index
      menu_items[index] = Menu.item(item_text, item)
    end

    local menu_options = {
      min_width = vim.api.nvim_strwidth(border_top_text),
      max_width = max_width,
      max_height = max_height,
      lines = menu_items,
      on_close = function() on_done(nil, nil) end,
      on_submit = function(item) on_done(item.__raw_item or item, item.index) end,
    }

    UISelect.super.init(self, popup_options, menu_options)

    if vim.g.lightboat_opt.ui_select_on_init and type(vim.g.lightboat_opt.ui_select_on_init) == 'function' then
      vim.g.lightboat_opt.ui_select_on_init(self, items, opts, on_done)
    end
  end

  local select_ui = nil

  vim.ui.select = function(items, opts, on_choice)
    assert(type(on_choice) == 'function', 'missing on_choice function')

    if select_ui then
      -- ensure single ui.select operation
      vim.notify('Another select is pending, please finish it first.', vim.log.levels.ERROR, { title = 'Light Boat' })
      return
    end

    select_ui = UISelect(items, opts, function(item, index)
      if select_ui then
        -- if it's still mounted, unmount it
        select_ui:unmount()
      end
      -- pass the select value
      on_choice(item, index)
      -- indicate the operation is done
      select_ui = nil
    end)

    select_ui:mount()
  end
end
local function override_ui_input()
  local Input = require('nui.input')
  local UIInput = Input:extend('UIInput')
  function UIInput:init(opts, on_done)
    local border_top_text = get_prompt_text(opts.prompt, '[Input]')
    local default_value = tostring(opts.default or '')
    UIInput.super.init(self, {
      relative = 'cursor',
      position = { row = 2, col = 0 },
      size = { width = math.floor(math.max(40, 1.5 * vim.api.nvim_strwidth(default_value))) },
      border = { style = vim.o.winborder, text = { top = border_top_text, top_align = 'left' } },
      win_options = { winhighlight = 'NormalFloat:Normal,FloatBorder:Normal' },
    }, {
      default_value = default_value,
      on_close = function() on_done(nil) end,
      on_submit = function(value) on_done(value) end,
    })
    if vim.g.lightboat_opt.ui_input_on_init and type(vim.g.lightboat_opt.ui_input_on_init) == 'function' then
      vim.g.lightboat_opt.ui_input_on_init(self, opts, on_done)
    end
  end
  local input_ui
  vim.ui.input = function(opts, on_confirm)
    assert(type(on_confirm) == 'function', 'missing on_confirm function')

    if input_ui then
      vim.notify('Another input is pending, please finish it first.', vim.log.levels.ERROR, { title = 'Light Boat' })
      return
    end

    input_ui = UIInput(opts, function(value)
      if input_ui then
        -- if it's still mounted, unmount it
        input_ui:unmount()
      end
      -- pass the input value
      on_confirm(value)
      -- indicate the operation is done
      input_ui = nil
    end)

    input_ui:mount()
  end
end
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

local function auto_start_lsp()
  vim.lsp.config('*', vim.tbl_deep_extend('force', capabilities, vim.lsp.config['*'].capabilities or {}))
  -- Make sure the lspconfig is loaded
  if util.plugin_available('nvim-lspconfig') and not _G.plugin_loaded['nvim-lspconfig'] then require('lspconfig') end
  local lsp_path = vim.fn.stdpath('config')
  if lsp_path:sub(-1) ~= '/' then lsp_path = lsp_path .. '/' end
  lsp_path = lsp_path .. 'after/lsp'
  local servers = vim.fn.glob(lsp_path .. '/**/*.lua', true, true)
  servers = vim.tbl_map(function(path) return vim.fn.fnamemodify(path, ':t:r') end, servers)
  if #servers > 0 then vim.lsp.enable(servers) end
end

local enabled = function(name) return vim.b[name] == true or vim.b[name] == nil and vim.g[name] == true end

local setup_autocmd = function()
  local group = vim.api.nvim_create_augroup('LightBoatAutoCmd', { clear = true })
  if vim.g.lightboat_opt.big_file_detection and #vim.g.lightboat_opt.big_file_detection > 0 then
    vim.api.nvim_create_autocmd(vim.g.lightboat_opt.big_file_detection, {
      group = group,
      callback = function(ev)
        if vim.b.big_file_status == nil then vim.b.big_file_status = false end
        local is_big = util.buffer.big(ev.buf, ev.event)
        local old_status = vim.b.big_file_status
        vim.b.big_file_status = is_big
        if type(vim.b.big_file_callback) == 'function' then
          vim.b.big_file_callback({ buffer = ev.buf, old_status = old_status, new_status = is_big })
        elseif type(vim.g.big_file_callback) == 'function' then
          vim.g.big_file_callback({ buffer = ev.buf, old_status = old_status, new_status = is_big })
        end
      end,
    })
  end
  vim.api.nvim_create_autocmd('ModeChanged', {
    group = group,
    callback = function()
      if not enabled('nohlsearch_auto_run') or util.in_macro_executing() then return end
      if vim.tbl_contains({ 'i', 'ic', 'ix', 'R', 'Rc', 'Rx', 'Rv', 'Rvc', 'Rvx' }, vim.api.nvim_get_mode().mode) then
        -- We must schedule here
        vim.schedule_wrap(vim.cmd)('nohlsearch')
      end
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'LazyLoad',
    callback = function(args)
      _G.plugin_loaded[args.data] = true
      if _G.plugin_loaded['nui.nvim'] and not done['nui.nvim'] then
        done['nui.nvim'] = true
        if vim.g.lightboat_opt.override_ui_input then override_ui_input() end
        if vim.g.lightboat_opt.override_ui_select then override_ui_select() end
      end
      if _G.plugin_loaded['telescope.nvim'] and not done['telescope.nvim'] then
        done['telescope.nvim'] = true
        local t = require('telescope')
        if util.plugin_available('telescope-fzf-native.nvim') then t.load_extension('fzf') end
        if util.plugin_available('telescope-frecency.nvim') then t.load_extension('frecency') end
        if util.plugin_available('telescope-live-grep-args.nvim') then t.load_extension('live_grep_args') end
      end
      if _G.plugin_loaded['nvim-treesitter-endwise'] and not done['nvim-treesitter-endwise'] then
        done['nvim-treesitter-endwise'] = true
        require('nvim-treesitter-endwise').init()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
          if require('nvim-treesitter-endwise').is_supported(lang) then
            require('nvim-treesitter.endwise').attach(buf)
          end
        end
      end
      if
        _G.plugin_loaded['mason.nvim']
        and not done['nvim.mason']
        and #vim.g.lightboat_opt.mason_ensure_installed > 0
      then
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
        _G.plugin_loaded['nvim-treesitter']
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
      if _G.plugin_loaded['blink.cmp'] and not done['blink.cmp'] then
        done['blink.cmp'] = true
        local original = require('blink.cmp.completion.list').show
        -- HACK:
        -- This is a hack, see https://github.com/saghen/blink.cmp/issues/1222#issuecomment-2891921393
        require('blink.cmp.completion.list').show = function(ctx, items_by_source)
          local seen = {}
          local function filter(item)
            if seen[item.label] then return false end
            seen[item.label] = true
            return true
          end
          local priority = {}
          if vim.b.blink_cmp_unique_priority then
            priority = util.get(vim.b.blink_cmp_unique_priority, ctx)
          elseif vim.g.blink_cmp_unique_priority then
            priority = util.get(vim.g.blink_cmp_unique_priority, ctx)
          end
          for id in vim.iter(priority) do
            items_by_source[id] = items_by_source[id] and vim.iter(items_by_source[id]):filter(filter):totable()
          end
          return original(ctx, items_by_source)
        end
      end
    end,
  })
  local guessed = {}
  local conform_available = util.plugin_available('conform.nvim')
  local guess_indent_available = util.plugin_available('guess-indent.nvim')
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = group,
    callback = function(args)
      if not enabled('conform_on_save') then return end
      if not conform_available then
        vim.notify(
          'conform.nvim is not available, please disable conform_on_save',
          vim.log.levels.WARN,
          { title = 'Light Boat' }
        )
      end
      local buffer = args.buf
      require('conform').format({ bufnr = buffer }, function(err)
        if err then vim.schedule_wrap(vim.notify)(err, vim.log.levels.ERROR, { title = 'Conform' }) end
        if enabled('conform_on_save_reguess_indent') then
          if not guess_indent_available then
            vim.schedule_wrap(vim.notify)(
              'guess-indent.nvim is not available, please disable conform_on_save_reguess_indent',
              vim.log.levels.WARN,
              { title = 'Light Boat' }
            )
          elseif not err and not guessed[buffer] then
            guessed[buffer] = true
            require('guess-indent').set_from_buffer(buffer, true, false)
          end
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
      local size = 0
      for _, line in ipairs(vim.v.event.regcontents) do
        size = size + #line
      end
      if size > 0 and (not limit or size < limit) then vim.hl.on_yank({ timeout = timeout }) end
    end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function()
      -- PERF:
      if util.treesitter_available('highlights') and enabled('treesitter_highlight_auto_start') then
        vim.treesitter.start()
      end
      if util.treesitter_available('folds') and enabled('treesitter_foldexpr_auto_set') then
        vim.wo[0][0].foldmethod = 'expr'
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      end
      if enabled('treesitter_indentexpr_auto_set') then
        if not util.plugin_available('nvim-treesitter') then
          vim.notify(
            'nvim-treesitter is not available, please disable treesitter_indentexpr_auto_set',
            vim.log.levels.WARN,
            { title = 'Light Boat' }
          )
        elseif util.treesitter_available('indents') then
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
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
  -- util.network.check()
  -- util.start_to_detect_color()
  util.git.detect()
  setup_autocmd()
  -- We use this code to make the fold sign at the end of the status column and clickable as usually
  local function fold_clickable(lnum) return vim.fn.foldlevel(lnum) > vim.fn.foldlevel(lnum - 1) and vim.v.virtnum <= 0 end
  _G.get_statuscol = function() return '%s%l%=' .. (fold_clickable(vim.v.lnum) and '%C' or ' ') .. ' ' end
  vim.o.statuscolumn = '%!v:lua.get_statuscol()'
  auto_start_lsp()
  pcall(function() require('vim._extui').enable({}) end)
end

return M
