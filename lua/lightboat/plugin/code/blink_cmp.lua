local util = require('lightboat.util')
local network = util.network
local config = require('lightboat.config')
local c
local M = {}

--- Auto confirm when:
--- * selecting nothing and the first item is a snippet or path
---   whose label is started with the input
function M.extra_accept(cmp)
  if not cmp.is_visible() then return false end
  local completion_list = require('blink.cmp.completion.list')
  if completion_list.get_selected_item() then return cmp.accept() end
  local snippet_kind = require('blink.cmp.types').CompletionItemKind.Snippet
  local first = completion_list.items[1]
  local input_str = completion_list.context.line:sub(
    completion_list.context.bounds.start_col,
    completion_list.context.bounds.start_col + completion_list.context.bounds.length
  )
  if
    first
    and first.label:sub(1, #input_str) == input_str
    and (first.kind == snippet_kind or first.source_name == 'Path')
  then
    return cmp.accept({ index = 1 })
  end
end

-- HACK:
-- Find a better way to check if we are inside some types
--- @param types string[]
--- @return boolean|nil
--- Returns true if the cursor is inside a block of the specified types,
--- false if not, or nil if unable to determine.
function M.inside_block(types)
  local node_under_cursor = vim.treesitter.get_node()
  local parser = vim.treesitter.get_parser(nil, nil, { error = false })
  if not parser or not node_under_cursor then return nil end
  local query = vim.treesitter.query.get(parser:lang(), 'highlights')
  if not query then return nil end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  for id, node, _ in query:iter_captures(node_under_cursor, 0, row, row + 1) do
    for _, t in ipairs(types) do
      if query.captures[id]:find(t) then
        local start_row, start_col, end_row, end_col = node:range()
        if start_row <= row and row <= end_row then
          if start_row == row and end_row == row then
            if start_col <= col and col <= end_col then return true end
          elseif start_row == row then
            if start_col <= col then return true end
          elseif end_row == row then
            if col <= end_col then return true end
          else
            return true
          end
        end
      end
    end
  end
  return false
end

function M.default_sources()
  -- HACK:
  -- path source works not good enough
  local res = { 'lsp', 'path' }
  if not vim.bo.filetype:match('dap') and not vim.bo.filetype:match('sagarename') then table.insert(res, 'snippets') end
  if vim.bo.filetype == 'AvanteInput' then
    table.insert(res, 'avante')
  elseif vim.tbl_contains({ 'gitcommit', 'octo' }, vim.bo.filetype) and network.status() then
    table.insert(res, 'git')
  end
  if
    vim.tbl_contains({ 'markdown', 'gitcommit', 'text', 'Avante', 'AvanteInput', 'octo' }, vim.bo.filetype)
    or M.inside_block({ 'comment' }) ~= false
  then
    vim.list_extend(res, {
      'buffer',
      'ripgrep',
      'dictionary',
    })
  end
  return res
end

local operation = {
  -- HACK:
  -- We add this mapping, because blink may disappear when input some non-alphenumeric
  -- We should remove this mapping when blink can handle this case
  ['<c-x>'] = { function(cmp) cmp.show({ providers = { 'snippets' } }) end },
  ['<c-s>'] = { 'show_signature', 'hide_signature', 'fallback' },
  -- FIX:
  -- This cr not work for cmdline
  ['<cr>'] = { M.extra_accept, 'fallback' },
  ['<tab>'] = { 'snippet_forward', 'fallback' },
  ['<s-tab>'] = { 'snippet_backward', 'fallback' },
  ['<c-u>'] = { 'scroll_documentation_up', 'fallback' },
  ['<c-d>'] = { 'scroll_documentation_down', 'fallback' },
  ['<c-j>'] = { 'select_next', 'fallback' },
  ['<c-k>'] = { 'select_prev', 'fallback' },
  ['<c-c>'] = { 'cancel', 'fallback' },
}

local spec = {
  'saghen/blink.cmp',
  version = '*',
  dependencies = {
    'Kaiser-Yang/blink-cmp-git',
    'Kaiser-Yang/blink-cmp-avante',
    'Kaiser-Yang/blink-cmp-dictionary',
    'rafamadriz/friendly-snippets',
    'mikavilpas/blink-ripgrep.nvim',
  },
  event = { 'InsertEnter', 'CmdlineEnter' },
  opts = {
    fuzzy = { use_frecency = false },
    completion = {
      accept = { auto_brackets = { enabled = true } },
      keyword = { range = 'prefix' },
      list = { selection = { preselect = false, auto_insert = true } },
      trigger = { show_on_insert_on_trigger_character = false },
      menu = {
        border = 'rounded',
        max_height = 15,
        scrolloff = 0,
        draw = {
          align_to = 'label',
          padding = 0,
          columns = {
            { 'kind_icon' },
            { 'label', 'label_description', gap = 1 },
            { 'source_name' },
          },
          components = {
            source_name = {
              text = function(ctx) return '[' .. ctx.source_name .. ']' end,
            },
          },
        },
      },
      documentation = { auto_show = true, window = { border = 'rounded' } },
    },
    signature = {
      enabled = true,
      window = { border = 'rounded', show_documentation = false },
    },
    --- @type table<string, string|table>
    keymap = { preset = 'none' },
    cmdline = {
      --- @type table<string, string|table>
      keymap = { preset = 'none' },
      completion = {
        menu = { auto_show = true },
        ghost_text = { enabled = false },
        list = { selection = { preselect = false, auto_insert = true } },
      },
    },
    sources = {
      default = M.default_sources,
      providers = {
        avante = {
          name = 'Avante',
          module = 'blink-cmp-avante',
        },
        git = {
          name = 'Git',
          module = 'blink-cmp-git',
        },
        dictionary = {
          name = 'Dict',
          module = 'blink-cmp-dictionary',
          min_keyword_length = 3,
          opts = {
            dictionary_files = {
              util.get_light_boat_root() .. '/dict/en_dict.txt',
            },
          },
        },
        lsp = {
          fallbacks = {},
          transform_items = function(_, items)
            local TYPE_ALIAS = require('blink.cmp.types').CompletionItemKind
            return vim.tbl_filter(function(item)
              -- Remove snippets, texts and some keywords from completion list
              return item.kind ~= TYPE_ALIAS.Snippet
                and item.kind ~= TYPE_ALIAS.Text
                and not (
                  c.enabled
                  and item.kind == TYPE_ALIAS.Keyword
                  and c.ignored_keyword
                  and c.ignored_keyword[vim.bo.filetype]
                  and vim.tbl_contains(c.ignored_keyword[vim.bo.filetype], item.label)
                )
            end, items)
          end,
        },
        snippets = { name = 'Snip' },
        path = { opts = { trailing_slash = false, show_hidden_files_by_default = util.in_config_dir() } },
        ripgrep = {
          name = 'RG',
          module = 'blink-ripgrep',
          opts = {
            prefix_min_len = 3,
            fallback_to_regex_highlighting = true,
            backend = {
              context_size = 5,
              project_root_fallback = false,
              ripgrep = {
                search_casing = '--smart-case',
                additional_rg_options = { '--max-count', '5' },
              },
            },
          },
        },
      },
    },
  },
  opts_extend = { 'sources.default' },
}

function M.spec() return spec end

function M.clear()
  local ripgrep_c = spec.opts.sources.providers.ripgrep.opts
  ripgrep_c.project_root_marker = nil
  ripgrep_c.backend.ripgrep.max_filesize = nil
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.extra.blink_cmp', function()
  c = config.get().blink_cmp
  if not c.enabled then return nil end
  for k, v in pairs(c.keys) do
    if not v or not operation[k] then goto continue end
    spec.opts.keymap[v.key] = operation[k]
    if vim.tbl_contains({ '<cr>', '<c-j>', '<c-k>' }, k) then spec.opts.cmdline.keymap[v.key] = operation[k] end
    ::continue::
  end
  local extra_c = config.get().extra
  local ripgrep_c = spec.opts.sources.providers.ripgrep.opts
  if extra_c.big_file.enabled then ripgrep_c.backend.ripgrep.max_filesize = extra_c.big_file.big_file_total or nil end
  ripgrep_c.project_root_marker = extra_c.root_markers or nil
  return spec
end, M.clear)

return M
