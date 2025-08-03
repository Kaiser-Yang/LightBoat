local util = require('lightboat.util')
local buffer = util.buffer
local feedkeys = util.key.feedkeys
local rep_move = require('lightboat.extra.rep_move')
local config = require('lightboat.config')
local map = util.key.set
local group
local c
local prev_git, next_git = rep_move.make(
  function(state) require('neo-tree.sources.filesystem.commands').prev_git_modified(state) end,
  function(state) require('neo-tree.sources.filesystem.commands').next_git_modified(state) end
)

local M = {}
local current_file

--- @param source 'git_status' | 'filesystem' | 'document_symbols'
function M.neo_tree_toggle_wrap(source)
  return function()
    if vim.bo.filetype ~= 'neo-tree' then current_file = vim.fn.expand('%:p') end
    local neo_tree_win = buffer.get_win_with_filetype('neo%-tree')[1]
    local cur_win = vim.api.nvim_get_current_win()
    if neo_tree_win and neo_tree_win ~= cur_win then vim.api.nvim_set_current_win(neo_tree_win) end
    local reveal = neo_tree_win == cur_win and source ~= 'document_symbols'
    require('neo-tree.command').execute({
      source = source,
      dir = reveal and vim.fs.root(0, c.extra.root_markers) or nil,
      reveal = reveal,
      reveal_file = reveal and (current_file or vim.fn.getcwd()) or nil,
    })
  end
end

local function on_file_moved(data)
  if not Snacks then return end
  Snacks.rename.on_rename_file(data.source, data.destination)
end

local operation = {
  ['<c-q>'] = M.neo_tree_toggle_wrap('git_status'),
  ['<c-e>'] = M.neo_tree_toggle_wrap('filesystem'),
  ['<c-w>'] = M.neo_tree_toggle_wrap('document_symbols'),
}

function M.toggle_or_open(state)
  local node = state.tree:get_node()
  if node.type ~= 'directory' and not node:has_children() then
    state.commands.open_with_window_picker(state)
  else
    state.commands.toggle_node(state)
  end
end

function M.collapse_all_under_cursor(state)
  local renderer = require('neo-tree.ui.renderer')
  local function collapse(u)
    if u == nil then return end
    if u:is_expanded() then u:collapse() end
    for _, v in pairs(state.tree:get_nodes(u:get_id())) do
      collapse(v)
    end
  end
  local node_under_cursor = state.tree:get_node()
  if node_under_cursor:is_expanded() then
    collapse(node_under_cursor)
  else
    local parent_id = node_under_cursor:get_parent_id()
    renderer.focus_node(state, parent_id)
    for _, child in pairs(state.tree:get_nodes(parent_id)) do
      collapse(child)
    end
  end
  renderer.redraw(state)
end

function M.expand_all_under_cursor(state)
  local node_under_cursor = state.tree:get_node()
  if node_under_cursor.type == 'directory' then
    state.commands.expand_all_nodes(state, node_under_cursor)
    return
  end
  local function expand(u)
    if u == nil then return end
    if u:has_children() and not u:is_expanded() then u:expand() end
    for _, v in pairs(state.tree:get_nodes(u:get_id())) do
      expand(v)
    end
  end
  expand(node_under_cursor)
  require('neo-tree.ui.renderer').redraw(state)
end

function M.collapse_or_goto_parent(state)
  local node = state.tree:get_node()
  if node:is_expanded() then
    state.commands.toggle_node(state)
  else
    require('neo-tree.ui.renderer').focus_node(state, node:get_parent_id())
  end
end

function M.enter_dir_or_open_file(state)
  local node = state.tree:get_node()
  if node.type == 'directory' then
    if state.commands.set_root then state.commands.set_root(state) end
  else
    state.commands.open_with_window_picker(state)
  end
end

function M.copy_node_info(state)
  local node = state.tree:get_node()
  local filepath = node:get_id()
  local filename = node.name
  local modify = vim.fn.fnamemodify
  local results = {
    { key = 'FILENAME', value = filename },
    { key = 'PATH (CWD)', value = modify(filepath, ':.') },
    { key = 'PATH', value = filepath },
    { key = 'URI', value = vim.uri_from_fname(filepath) },
    { key = 'BASENAME', value = modify(filename, ':r') },
    { key = 'EXTENSION', value = modify(filename, ':e') },
    { key = 'PATH (HOME)', value = modify(filepath, ':~') },
  }
  local vals = {}
  local options = {}
  for i, item in ipairs(results) do
    options[i] = item.key
    vals[item.key] = item.value
  end
  if #options <= 10 then
    local autocmd_id
    autocmd_id = vim.api.nvim_create_autocmd('BufEnter', {
      group = group,
      callback = function(ev)
        if vim.bo[ev.buf].filetype == 'snacks_picker_input' then
          vim.schedule(function() vim.cmd('stopinsert') end)
          for i = 1, #options do
            if i > 10 then break end
            local key = i < 10 and tostring(i) or '0'
            map('n', key, 'i' .. key .. '<cr>', { buffer = ev.buf, remap = true })
          end
        end
        vim.api.nvim_del_autocmd(autocmd_id)
      end,
    })
  end
  vim.ui.select(options, {
    prompt = 'Choose to copy to clipboard:',
    format_item = function(item) return ('%s: %s'):format(item, vals[item]) end,
  }, function(choice)
    if not choice or not vals[choice] then return end
    local result = vals[choice]
    vim.fn.setreg('"', result)
    vim.fn.setreg('+', result)
    vim.notify('Copied: ' .. result)
  end)
end

local spec = {
  'nvim-neo-tree/neo-tree.nvim',
  branch = 'v3.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
    {
      's1n7ax/nvim-window-picker',
      version = '2.*',
      opts = {
        hint = 'floating-big-letter',
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = {
              'neo-tree',
              'neo-tree-popup',
              'notify',
              'smear-cursor',
              'snacks_notif',
            },
            buftype = { 'terminal', 'quickfix' },
          },
        },
        prompt_message = '',
        highlights = {
          statusline = {
            unfocused = {
              fg = '#ededed',
              bg = '#3fa4cc',
              bold = true,
            },
          },
        },
      },
    },
  },
  opts = {
    sources = { 'filesystem', 'git_status', 'document_symbols' },
    source_selector = {
      winbar = true,
      sources = { { source = 'git_status' }, { source = 'document_symbols' }, { source = 'filesystem' } },
    },
    sort_case_insensitive = true,
    use_default_mappings = false,
    default_component_configs = {
      git_status = {
        symbols = {
          modified = '',
          renamed = '➜',
          untracked = '★',
          ignored = '◌',
          unstaged = '✗',
          staged = '✓',
        },
        width = 2,
        align = 'left',
      },
      file_size = {
        align = 'right',
        required_width = 0,
      },
      last_modified = {
        align = 'right',
        required_width = 0,
      },
      symlink_target = {
        enabled = true,
        align = 'right',
        required_width = 0,
      },
      created = {
        enabled = true,
        align = 'right',
        required_width = 0,
      },
    },
    window = {
      width = function() return math.ceil(math.max(30, 0.14 * vim.o.columns)) end,
      mappings = {
        ['e'] = 'toggle_auto_expand_width',
        ['<c-c>'] = 'cancel',
        ['<leader>j'] = 'split_with_window_picker',
        ['<leader>k'] = 'split_with_window_picker',
        ['<leader>l'] = 'vsplit_with_window_picker',
        ['<leader>h'] = 'vsplit_with_window_picker',
        ['<c-s>'] = 'split_with_window_picker',
        ['<c-v>'] = 'vsplit_with_window_picker',
        ['v'] = { function(_) feedkeys('V', 'n') end, desc = 'Visual select' },
        ['<f5>'] = 'refresh',
        ['?'] = 'show_help',
        ['<2-LeftMouse>'] = { M.toggle_or_open, desc = 'Toggle or Open' },
        ['H'] = { M.collapse_all_under_cursor, desc = 'Collapse all under cursor' },
        ['L'] = { M.expand_all_under_cursor, desc = 'Expand all under cursor' },
        ['<cr>'] = { M.enter_dir_or_open_file, desc = 'Enter Dir or Open File' },
        ['h'] = { M.collapse_or_goto_parent, desc = 'Collapse or Go To Parrent' },
        ['l'] = { M.toggle_or_open, desc = 'Toggle or Open' },
      },
    },
    filesystem = {
      filtered_items = {
        hide_dotfiles = not util.in_config_dir(),
        hide_hidden = not util.in_config_dir(),
      },
      window = {
        mappings = {
          ['r'] = 'rename',
          ['<bs>'] = 'navigate_up',
          ['d'] = 'delete',
          ['y'] = 'copy_to_clipboard',
          ['Y'] = { M.copy_node_info, desc = 'Copy node information to clipboard' },
          ['x'] = 'cut_to_clipboard',
          ['p'] = 'paste_from_clipboard',
          ['a'] = { 'add', config = { show_path = 'absolute' } },
          ['m'] = { 'move', config = { show_path = 'absolute' } },
          ['c'] = { 'copy', config = { show_path = 'absolute' } },
          ['o'] = { 'show_help', nowait = false, config = { title = 'Order by', prefix_key = 'o' } },
          ['oc'] = { 'order_by_created', nowait = false },
          ['od'] = { 'order_by_diagnostics', nowait = false },
          ['og'] = { 'order_by_git_status', nowait = false },
          ['om'] = { 'order_by_modified', nowait = false },
          ['on'] = { 'order_by_name', nowait = false },
          ['os'] = { 'order_by_size', nowait = false },
          ['ot'] = { 'order_by_type', nowait = false },
          ['[g'] = { prev_git, desc = 'Prev Git Modified' },
          [']g'] = { next_git, desc = 'Next Git Modified' },
          ['<m-i>'] = 'toggle_hidden',
          ['<m-h>'] = 'toggle_hidden',
        },
      },
    },
    git_status = {
      window = {
        mappings = {
          ['o'] = { 'show_help', nowait = false, config = { title = 'Order by', prefix_key = 'o' } },
          ['oc'] = { 'order_by_created', nowait = false },
          ['od'] = { 'order_by_diagnostics', nowait = false },
          ['og'] = { 'order_by_git_status', nowait = false },
          ['om'] = { 'order_by_modified', nowait = false },
          ['on'] = { 'order_by_name', nowait = false },
          ['os'] = { 'order_by_size', nowait = false },
          ['ot'] = { 'order_by_type', nowait = false },
        },
      },
    },
    document_symbols = {
      renderers = {
        root = { { 'name' } },
        symbol = {
          { 'indent', with_expanders = true },
          { 'kind_icon', default = '?' },
          { 'name' },
          { 'kind_name' },
        },
      },
    },
    renderers = {
      file = {
        { 'indent' },
        { 'icon' },
        { 'git_status' },
        { 'name' },
        { 'diagnostics', errors_only = false },
        { 'clipboard' },
        {
          'container',
          content = {
            { 'symlink_target', highlight = 'NeoTreeSymbolicLinkTarget', zindex = 40 },
            { 'file_size', zindex = 30 },
            { 'last_modified', zindex = 20 },
            { 'created', zindex = 10 },
          },
        },
      },
      directory = {
        { 'indent' },
        { 'icon' },
        { 'current_filter' },
        { 'git_status', hide_when_expanded = true },
        { 'name' },
        { 'diagnostics', errors_only = false, hide_when_expanded = true },
        { 'clipboard' },
        {
          'container',
          content = {
            { 'symlink_target', highlight = 'NeoTreeSymbolicLinkTarget', zindex = 40 },
            { 'file_size', zindex = 30 },
            { 'last_modified', zindex = 20 },
            { 'created', zindex = 10 },
          },
        },
      },
    },
    event_handlers = {
      {
        event = 'file_moved',
        handler = on_file_moved,
      },
      {
        event = 'file_renamed',
        handler = on_file_moved,
      },
      {
        event = 'neo_tree_window_after_open',
        handler = function()
          for _, win in ipairs(buffer.get_win_with_filetype('dap')) do
            local buf = vim.api.nvim_win_get_buf(win)
            if not vim.tbl_contains({ 'dap-repl', 'dapui_console' }, vim.bo[buf].filetype) then
              vim.api.nvim_win_close(win, true)
            end
          end
          vim.cmd('wincmd = ')
        end,
      },
    },
  },
  cmd = { 'Neotree' },
  keys = {},
}

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  spec.keys = {}
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.neo_tree', function()
  c = config.get()
  if not c.neo_tree.enabled then return nil end
  spec.keys = util.key.get_lazy_keys(operation, c.neo_tree.keys)
  group = vim.api.nvim_create_augroup('LightBoatNeoTree', {})
  vim.api.nvim_create_autocmd('BufEnter', {
    callback = function(_)
      if vim.bo.filetype ~= 'neo-tree-popup' then return end
      local current_line = vim.api.nvim_get_current_line()
      if current_line:match('^ y/n: $') then
        map({ 'n' }, 'y', 'iy<cr>', { buffer = true })
        map({ 'n' }, 'Y', 'iy<cr>', { buffer = true })
        map({ 'n' }, 'n', 'in<cr>', { buffer = true })
        map({ 'n' }, 'N', 'in<cr>', { buffer = true })
        if vim.api.nvim_get_mode().mode == 'i' then
          feedkeys('<esc>', 'n') -- back to normal
        end
      end
      map({ 'n', 'i' }, '<esc>', function()
        if vim.api.nvim_get_mode().mode == 'i' then
          feedkeys('<esc>', 'n') -- back to nromal
        else
          feedkeys('i<c-c>', 'm') -- quit
        end
      end, { buffer = true })
    end,
  })
  return spec
end, M.clear)

return M
