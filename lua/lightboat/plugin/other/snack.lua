local util = require('lightboat.util')
local on_key_ns_id
local config = require('lightboat.config')
local c
local big_file = require('lightboat.extra.big_file')
local function enable_scroll_for_filetype_once(filetype)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == filetype then
      vim.b[buf].snacks_animate_scroll = nil
      Snacks.scroll.check(win)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        vim.b[buf].snacks_animate_scroll = false
      end)
    end
  end
end

local feedkeys = util.key.feedkeys
local key_state = { hlsearch = false, diagnostic = false, mouse_scroll = false }

local function set_key_state(key)
  for k, _ in pairs(key_state) do
    if k ~= key then key_state[k] = false end
  end
  if key then key_state[key] = true end
end

local function on_finished()
  if key_state.mouse_scroll then
    key_state.mouse_scroll = false
  elseif key_state.hlsearch then
    key_state.hlsearch = false
    if util.search.cursor_in_match() then vim.cmd('set hlsearch') end
  elseif key_state.diagnostic then
    key_state.diagnostic = false
    local cursor = vim.api.nvim_win_get_cursor(0)
    if cursor[1] == 1 and cursor[2] == 0 then
      vim.schedule(function() feedkeys('w<cmd>Lspsaga diagnostic_jump_prev<cr>', 'n') end)
    else
      vim.schedule(function() feedkeys('b<cmd>Lspsaga diagnostic_jump_next<cr>', 'n') end)
    end
  end
end

local M = {}
local group

local function get_compile_command(filetype, filename)
  local filename_noext = vim.fn.fnamemodify(filename, ':t:r')
  local commands = {
    c = function()
      return string.format(
        'gcc -g -Wall "%s" -I include -o "%s.out" && echo RUNNING && time "./%s.out"',
        filename,
        filename_noext,
        filename_noext
      )
    end,
    cpp = function()
      return string.format(
        'g++ -g -Wall -std=c++17 -I include "%s" -o "%s.out" && echo RUNNING && time "./%s.out"',
        filename,
        filename_noext,
        filename_noext
      )
    end,
    java = function() return string.format('javac "%s" && echo RUNNING && time java "%s"', filename, filename_noext) end,
    sh = function() return string.format('time "./%s"', filename) end,
    python = function() return string.format('time python "%s"', filename) end,
    lua = function() return string.format('time lua "%s"', filename) end,
  }
  local cmd_fn = commands[filetype]
  return cmd_fn and cmd_fn() or ''
end

M.run_single_file = big_file.big_file_check_wrap(function()
  local filetype = vim.bo.filetype
  if vim.tbl_contains(c.extra.markdown_fts, filetype) then
    vim.cmd('RenderMarkdown buf_toggle')
    return
  end

  local fullpath = vim.fn.expand('%:p')
  local filename = vim.fn.fnamemodify(fullpath, ':t')
  local command = get_compile_command(filetype, filename)
  if command == '' then
    vim.notify('Unsupported filetype', vim.log.levels.WARN)
    return
  end
  local directory = vim.fn.fnamemodify(fullpath, ':h')
  command = 'cd ' .. directory .. ' && ' .. command
  Snacks.terminal(command, { start_insert = true, auto_insert = true, auto_close = false })
end)

M.preview_scroll_up = function(picker)
  enable_scroll_for_filetype_once('snacks_picker_preview')
  picker.opts.actions.preview_scroll_up.action()
end

M.preview_scroll_down = function(picker)
  enable_scroll_for_filetype_once('snacks_picker_preview')
  picker.opts.actions.preview_scroll_down.action()
end

function M.grep() Snacks.picker.grep(util.resolve_opts(c.snack.keys['<c-f>'].opts)) end

function M.files() Snacks.picker.files(util.resolve_opts(c.snack.keys['<c-p>'].opts)) end

function M.resume() Snacks.picker.resume(util.resolve_opts(c.snack.keys['<c-y>'].opts)) end

local operation = {
  ['<c-y>'] = M.resume,
  ['z='] = function() Snacks.picker.spelling(util.resolve_opts(c.snack.keys['z='].opts)) end,
  ['<c-p>'] = M.files,
  ['<c-f>'] = M.grep,
  -- PERF:
  -- disabled in large files
  ['<leader><leader>'] = big_file.big_file_check_wrap(
    function() Snacks.picker.lines(util.resolve_opts(c.snack.keys['<leader><leader>'].opts)) end
  ),
  ['<leader>r'] = M.run_single_file,
}

local spec = {
  'Kaiser-Yang/snacks.nvim',
  branch = 'develop',
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = false },
    dashboard = { enabled = false },
    image = { enabled = vim.fn.has('wsl') == 0 },
    indent = {
      enabled = true,
      animate = { enabled = true, duration = { total = 300 } },
      chunk = { enabled = true, char = { corner_top = '╭', corner_bottom = '╰' } },
      filter = function(buf)
        return vim.g.snacks_indent ~= false
          and vim.b[buf].snacks_indent ~= false
          and vim.bo[buf].buftype == ''
          and vim.bo[buf].filetype ~= 'markdown'
      end,
    },
    input = { enabled = false },
    picker = {
      ui_select = true,
      save_as_last = false,
      enabled = vim.fn.executable('rg') == 1,
      jump = { match = true },
      previewers = { file = {} },
      win = {
        input = {
          keys = {
            ['<up>'] = { 'history_back', mode = { 'i', 'n' } },
            ['<down>'] = { 'history_back', mode = { 'i', 'n' } },
            ['<c-j>'] = { 'list_down', mode = { 'n', 'i' } },
            ['<c-k>'] = { 'list_up', mode = { 'n', 'i' } },
            ['<c-u>'] = { M.preview_scroll_up, mode = { 'i', 'n' } },
            ['<c-d>'] = { M.preview_scroll_down, mode = { 'i', 'n' } },
            ['<c-c>'] = { 'close', mode = { 'n', 'i' } },
            ['<f1>'] = { 'toggle_help_input', mode = { 'i', 'n' } },
            ['<cr>'] = { 'confirm', mode = { 'n', 'i' } },
            ['<c-s>'] = { 'edit_split', mode = { 'i', 'n' } },
            ['<c-v>'] = { 'edit_vsplit', mode = { 'i', 'n' } },
            ['<c-r><c-w>'] = { 'insert_cword', mode = 'i', desc = 'Insert the word under cursor' },
            ['<c-r><c-l>'] = { 'insert_line', mode = 'i', desc = 'Insert current line' },
            ['<c-r><c-p>'] = { 'insert_file_full', mode = 'i', desc = 'Insert file full path' },
            ['<c-r><c-f>'] = { 'insert_file', mode = 'i', desc = 'Insert filename under cursor' },
            ['<c-r>W'] = { 'insert_cWORD', mode = 'i', desc = 'Insert the WORD under cursor' },
            ['<c-r>%'] = { 'insert_filename', mode = 'i', desc = "Insert current buffer's filename" },
            ['<c-r>w'] = { 'insert_cword', mode = 'i', desc = 'Insert the word under cursor' },
            ['<c-r>l'] = { 'insert_line', mode = 'i', desc = 'Insert current line' },
            ['<c-r>p'] = { 'insert_file_full', mode = 'i', desc = 'Insert file full path' },
            ['<c-r>f'] = { 'insert_file', mode = 'i', desc = 'Insert filename under cursor' },
            ['<c-r>5'] = { 'insert_filename', mode = 'i', desc = "Insert current buffer's filename" },
            ['<a-g>'] = { 'toggle_live', mode = { 'i', 'n' } },
            ['<a-h>'] = { 'toggle_hidden', mode = { 'i', 'n' } },
            ['<a-w>'] = { 'toggle_focus', mode = { 'i', 'n' } },
            ['<a-m>'] = { 'toggle_maximize', mode = { 'i', 'n' } },
            ['<a-p>'] = { 'toggle_preview', mode = { 'i', 'n' } },
            ['<a-f>'] = { 'toggle_follow', mode = { 'i', 'n' } },
            ['<a-i>'] = { 'toggle_ignored', mode = { 'i', 'n' } },
            ['<m-a>'] = { 'select_all', mode = { 'n', 'i' } },
            ['<tab>'] = { 'select_and_next', mode = { 'i', 'n' } },
            ['<s-tab>'] = { 'select_and_prev', mode = { 'i', 'n' } },
            ['?'] = 'toggle_help_input',
            ['G'] = 'list_bottom',
            ['gg'] = 'list_top',
            ['j'] = 'list_down',
            ['k'] = 'list_up',
            ['q'] = 'close',
            ['<esc>'] = 'cancel',
            ['<c-q>'] = { 'qflist', mode = { 'i', 'n' } },
            ['<c-a>'] = false,
            ['<c-up>'] = false,
            ['<c-down>'] = false,
            ['<c-w>H'] = false,
            ['<c-w>J'] = false,
            ['<c-w>K'] = false,
            ['<c-w>L'] = false,
            ['<c-t>'] = false,
            ['/'] = false,
            ['<s-cr>'] = false,
            ['<c-w>'] = false,
            ['<c-r>#'] = false,
          },
        },
        list = {
          --- @type table<string, string|boolean|table>
          keys = {
            ['?'] = 'toggle_help_list',
            ['<f1>'] = 'toggle_help_list',
            ['G'] = 'list_bottom',
            ['gg'] = 'list_top',
            ['j'] = 'list_down',
            ['k'] = 'list_up',
            ['q'] = 'close',
            ['zb'] = 'list_scroll_bottom',
            ['zt'] = 'list_scroll_top',
            ['zz'] = 'list_scroll_center',
            ['i'] = 'focus_input',
            ['a'] = 'focus_input',
            ['o'] = 'focus_input',
            ['I'] = 'focus_input',
            ['A'] = 'focus_input',
            ['O'] = 'focus_input',
            ['<2-LeftMouse>'] = 'confirm',
            ['<cr>'] = 'confirm',
            ['<esc>'] = 'cancel',
            ['<c-d>'] = 'list_scroll_down',
            ['<c-u>'] = 'list_scroll_up',
            ['<a-w>'] = 'toggle_focus',
            ['<c-s>'] = 'edit_split',
            ['<c-v>'] = 'edit_vsplit',
            ['<a-m>'] = 'toggle_maximize',
            ['<a-p>'] = 'toggle_preview',
            ['<a-f>'] = 'toggle_follow',
            ['<a-i>'] = 'toggle_ignored',
            ['<a-h>'] = 'toggle_hidden',
            ['<m-a>'] = 'select_all',
            ['<tab>'] = 'select_and_next',
            ['<s-tab>'] = 'select_and_prev',
            ['<c-q>'] = 'qflist',
            ['<c-a>'] = false,
            ['<c-t>'] = false,
            ['<c-j>'] = false,
            ['<c-k>'] = false,
            ['<c-b>'] = false,
            ['<up>'] = false,
            ['<down>'] = false,
            ['<c-w>H'] = false,
            ['<c-w>J'] = false,
            ['<c-w>K'] = false,
            ['<c-w>L'] = false,
            ['/'] = false,
            ['<s-cr>'] = false,
          },
        },
        preview = {
          --- @type table<string, string|boolean|table>
          keys = {
            ['i'] = 'focus_input',
            ['a'] = 'focus_input',
            ['o'] = 'focus_input',
            ['I'] = 'focus_input',
            ['A'] = 'focus_input',
            ['O'] = 'focus_input',
            ['q'] = 'close',
            ['<esc>'] = 'cancel',
            ['<a-w>'] = 'cycle_win',
          },
        },
      },
    },
    scope = { enabled = false, treesitter = { enabled = false } },
    scroll = {
      enabled = true,
      filter = function(buf)
        return vim.g.snacks_scroll ~= false
          and vim.b[buf].snacks_scroll ~= false
          and vim.bo[buf].buftype ~= 'terminal'
          and vim.bo[buf].filetype ~= 'blink-cmp-menu'
      end,
      on_finished = on_finished,
    },
    statuscolumn = { enabled = false },
    words = { enabled = true },
    explorer = { enabled = false },
    notifier = { enabled = false },
    quickfile = { enabled = false },
    styles = {
      terminal = {
        position = 'float',
        border = 'rounded',
        keys = { q = false, gf = false, term_normal = false },
      },
    },
  },
  keys = {},
}

function M.spec() return spec end

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  if on_key_ns_id then
    vim.on_key(nil, on_key_ns_id)
    on_key_ns_id = nil
  end
  spec.opts.picker.previewers.file = {}
  spec.keys = {}
  if not c then return end
  if c.snack.keys['<c-f>'] then
    spec.opts.picker.win.input.keys[c.snack.keys['<c-f>'].key] = nil
    spec.opts.picker.win.list.keys[c.snack.keys['<c-f>'].key] = nil
    spec.opts.picker.win.preview.keys[c.snack.keys['<c-f>'].key] = nil
  end
  if c.snack.keys['<c-p>'] then
    spec.opts.picker.win.input.keys[c.snack.keys['<c-p>'].key] = nil
    spec.opts.picker.win.list.keys[c.snack.keys['<c-p>'].key] = nil
    spec.opts.picker.win.preview.keys[c.snack.keys['<c-p>'].key] = nil
  end
  if c.snack.keys['<c-y>'] then
    spec.opts.picker.win.input.keys[c.snack.keys['<c-y>'].key] = nil
    spec.opts.picker.win.list.keys[c.snack.keys['<c-y>'].key] = nil
    spec.opts.picker.win.preview.keys[c.snack.keys['<c-y>'].key] = nil
  end
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.snack', function()
  c = config.get()
  if not c.snack.enabled then return nil end
  if c.extra.big_file.enabled then
    spec.opts.picker.previewers.file = {
      max_size = c.extra.big_file.big_file_total,
      max_line_length = c.extra.big_file.big_file_avg_line,
    }
  end
  spec.keys = util.key.get_lazy_keys(operation, c.snack.keys)
  if c.snack.keys['<c-f>'] then
    spec.opts.picker.win.input.keys[c.snack.keys['<c-f>'].key] = { M.grep, mode = 'i' }
    spec.opts.picker.win.list.keys[c.snack.keys['<c-f>'].key] = { M.grep, mode = 'i' }
    spec.opts.picker.win.preview.keys[c.snack.keys['<c-f>'].key] = { M.grep, mode = 'i' }
  end
  if c.snack.keys['<c-p>'] then
    spec.opts.picker.win.input.keys[c.snack.keys['<c-p>'].key] = { M.files, mode = 'i' }
    spec.opts.picker.win.list.keys[c.snack.keys['<c-p>'].key] = { M.files, mode = 'i' }
    spec.opts.picker.win.preview.keys[c.snack.keys['<c-p>'].key] = { M.files, mode = 'i' }
  end
  if c.snack.keys['<c-y>'] then
    spec.opts.picker.win.input.keys[c.snack.keys['<c-y>'].key] = { M.resume, mode = 'i' }
    spec.opts.picker.win.list.keys[c.snack.keys['<c-y>'].key] = { M.resume, mode = 'i' }
    spec.opts.picker.win.preview.keys[c.snack.keys['<c-y>'].key] = { M.resume, mode = 'i' }
  end
  group = vim.api.nvim_create_augroup('LightBoatSnack', {})
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
      if vim.bo.filetype == 'snacks_picker_preview' then
        vim.b.snacks_animate_scroll = nil
        Snacks.scroll.check(vim.api.nvim_get_current_win())
      end
    end,
  })
  vim.api.nvim_create_autocmd('BufLeave', {
    group = group,
    callback = function()
      if vim.bo.filetype == 'snacks_picker_preview' then vim.b.snacks_animate_scroll = false end
    end,
  })
  vim.api.nvim_create_autocmd('WinScrolled', {
    group = group,
    callback = function()
      for win, changes in pairs(vim.v.event) do
        local delta = math.abs(changes.topline)
        win = tonumber(win)
        if not win then goto continue end
        local buf = vim.api.nvim_win_get_buf(win)
        if
          vim.g.snacks_animate_scroll ~= false
          and vim.b[buf].snacks_animate_scroll ~= false
          and (delta < c.snack.scroll_min_lines or delta > c.snack.scroll_max_lines)
        then
          vim.b[buf].snacks_animate_scroll = false
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) then return end
            vim.b[buf].snacks_animate_scroll = nil
            Snacks.scroll.check(win)
          end)
        end
        ::continue::
      end
    end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'snacks_picker_preview',
    group = group,
    callback = function() vim.b.snacks_animate_scroll = false end,
  })
  on_key_ns_id = vim.on_key(function(key, typed)
    key = typed or key
    local n = c.keymap.keys['n'] and c.keymap.keys['n'].key
    local N = c.keymap.keys['N'] and c.keymap.keys['N'].key
    if key == util.key.termcodes('<ScrollWheelUp>') or key == util.key.termcodes('<ScrollWheelDown>') then
      set_key_state('monse_scroll')
    elseif key == util.key.termcodes(n) or key == util.key.termcodes(N) then
      if vim.o.hlsearch then set_key_state('hlsearch') end
    elseif
      key == util.key.termcodes('Lspsaga diagnostic_jump_prev<cr>')
      or key == util.key.termcodes('Lspsaga diagnostic_jump_next<cr>')
    then
      set_key_state('diagnostic')
    elseif not key:match('^%s*$') then
      set_key_state()
    end
  end)
  return spec
end, M.clear)

return M
