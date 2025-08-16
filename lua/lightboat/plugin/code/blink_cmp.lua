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

local function pr_or_issue_configure_score_offset(items)
  -- Bonus to make sure items sorted as below:
  local keys = {
    -- place `kind_name` here
    { 'openIssue', 'openedIssue', 'reopenedIssue' },
    { 'openPR', 'openedPR' },
    { 'lockedIssue', 'lockedPR' },
    { 'completedIssue' },
    { 'draftPR' },
    { 'mergedPR' },
    { 'closedPR', 'closedIssue', 'not_plannedIssue', 'duplicateIssue' },
  }
  local bonus = 999999
  local bonus_score = {}
  for i = 1, #keys do
    for _, key in ipairs(keys[i]) do
      bonus_score[key] = bonus * (#keys - i)
    end
  end
  for i = 1, #items do
    local bonus_key = items[i].kind_name
    if bonus_score[bonus_key] then items[i].score_offset = bonus_score[bonus_key] end
    -- sort by number when having the same bonus score
    local number = items[i].label:match('[#!](%d+)')
    if number then
      if items[i].score_offset == nil then items[i].score_offset = 0 end
      items[i].score_offset = items[i].score_offset + tonumber(number)
    end
  end
end

local function get_args(command, token, remote, type)
  local args = require('blink-cmp-git.default.' .. remote)[type].get_command_args(command, token)
  args[#args] = args[#args] .. '?state=all'
  return args
end

local blink_cmp_git_opts = {
  kind_icons = {
    openPR = '',
    openedPR = '',
    closedPR = '',
    mergedPR = '',
    draftPR = '',
    lockedPR = '',
    openIssue = '',
    openedIssue = '',
    reopenedIssue = '',
    completedIssue = '',
    closedIssue = '',
    not_plannedIssue = '',
    duplicateIssue = '',
    lockedIssue = '',
  },
  commit = { enable = false },
  git_centers = {
    github = {
      pull_request = {
        get_command_args = function(command, token) return get_args(command, token, 'github', 'pull_request') end,
        get_kind_name = function(item)
          return item.locked and 'lockedPR'
            or item.draft and 'draftPR'
            or item.merged_at and 'mergedPR'
            or item.state .. 'PR'
        end,
        configure_score_offset = pr_or_issue_configure_score_offset,
      },
      issue = {
        get_command_args = function(command, token) return get_args(command, token, 'github', 'issue') end,
        get_kind_name = function(item)
          return item.locked and 'lockedIssue' or (item.state_reason or item.state) .. 'Issue'
        end,
        configure_score_offset = pr_or_issue_configure_score_offset,
      },
    },
    gitlab = {
      pull_request = {
        get_command_args = function(command, token) return get_args(command, token, 'gitlab', 'pull_request') end,
        get_kind_name = function(item)
          return item.discussion_locked and 'lockedPR' or item.draft and 'draftPR' or item.state .. 'PR'
        end,
        configure_score_offset = pr_or_issue_configure_score_offset,
      },
      issue = {
        get_command_args = function(command, token) return get_args(command, token, 'gitlab', 'issue') end,
        get_kind_name = function(item) return item.discussion_locked and 'lockedIssue' or item.state .. 'Issue' end,
        configure_score_offset = pr_or_issue_configure_score_offset,
      },
    },
  },
}

local spec = {
  { 'Kaiser-Yang/blink-cmp-git' },
  { 'Kaiser-Yang/blink-cmp-avante' },
  { 'Kaiser-Yang/blink-cmp-dictionary' },
  { 'rafamadriz/friendly-snippets' },
  { 'mikavilpas/blink-ripgrep.nvim' },
  {
    'saghen/blink.cmp',
    version = '*',
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
            columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'source_name' } },
            components = { source_name = { text = function(ctx) return '[' .. ctx.source_name .. ']' end } },
          },
        },
        documentation = { auto_show = true, window = { border = 'rounded' } },
      },
      signature = { enabled = true, window = { border = 'rounded', show_documentation = false } },
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
          avante = { name = 'Avante', module = 'blink-cmp-avante' },
          git = { name = 'Git', module = 'blink-cmp-git', opts = blink_cmp_git_opts },
          dictionary = {
            name = 'Dict',
            module = 'blink-cmp-dictionary',
            min_keyword_length = 3,
            opts = { dictionary_files = { util.get_light_boat_root() .. '/dict/en_dict.txt' } },
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
  },
}

function M.spec() return spec end

function M.clear()
  assert(spec[#spec][1] == 'saghen/blink.cmp')
  local ripgrep_c = spec[#spec].opts.sources.providers.ripgrep.opts
  ripgrep_c.project_root_marker = nil
  ripgrep_c.backend.ripgrep.max_filesize = nil
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.extra.blink_cmp', function()
  c = config.get().blink_cmp
  if not c.enabled then return nil end
  util.set_hls({
    { 0, 'BlinkCmpGitKindIconCommit', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindIconopenPR', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindIconopenedPR', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindIconclosedPR', { fg = '#f38ba8' } },
    { 0, 'BlinkCmpGitKindIconmergedPR', { fg = '#cba6f7' } },
    { 0, 'BlinkCmpGitKindIcondraftPR', { fg = '#9399b2' } },
    { 0, 'BlinkCmpGitKindIconlockedPR', { fg = '#f5c2e7' } },
    { 0, 'BlinkCmpGitKindIconopenIssue', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindIconopenedIssue', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindIconreopenedIssue', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindIconcompletedIssue', { fg = '#cba6f7' } },
    { 0, 'BlinkCmpGitKindIconclosedIssue', { fg = '#cba6f7' } },
    { 0, 'BlinkCmpGitKindIconnot_plannedIssue', { fg = '#9399b2' } },
    { 0, 'BlinkCmpGitKindIconduplicateIssue', { fg = '#9399b2' } },
    { 0, 'BlinkCmpGitKindIconlockedIssue', { fg = '#f5c2e7' } },
    { 0, 'BlinkCmpGitKindLabelCommitId', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindLabelopenPRId', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindLabelopenedPRId', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindLabelclosedPRId', { fg = '#f38ba8' } },
    { 0, 'BlinkCmpGitKindLabelmergedPRId', { fg = '#cba6f7' } },
    { 0, 'BlinkCmpGitKindLabeldraftPRId', { fg = '#9399b2' } },
    { 0, 'BlinkCmpGitKindLabellockedPRId', { fg = '#f5c2e7' } },
    { 0, 'BlinkCmpGitKindLabelopenIssueId', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindLabelopenedIssueId', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindLabelreopenedIssueId', { fg = '#a6e3a1' } },
    { 0, 'BlinkCmpGitKindLabelcompletedIssueId', { fg = '#cba6f7' } },
    { 0, 'BlinkCmpGitKindLabelclosedIssueId', { fg = '#cba6f7' } },
    { 0, 'BlinkCmpGitKindLabelnot_plannedIssueId', { fg = '#9399b2' } },
    { 0, 'BlinkCmpGitKindLabelduplicateIssueId', { fg = '#9399b2' } },
    { 0, 'BlinkCmpGitKindLabellockedIssueId', { fg = '#f5c2e7' } },
    { 0, 'BlinkCmpKindDict', { fg = '#a6e3a1' } },
  })
  assert(spec[#spec][1] == 'saghen/blink.cmp')
  for k, v in pairs(c.keys) do
    if not v or not operation[k] then goto continue end
    spec[#spec].opts.keymap[v.key] = operation[k]
    if vim.tbl_contains({ '<cr>', '<c-j>', '<c-k>' }, k) then spec[#spec].opts.cmdline.keymap[v.key] = operation[k] end
    ::continue::
  end
  local extra_c = config.get().extra
  local ripgrep_c = spec[#spec].opts.sources.providers.ripgrep.opts
  if extra_c.big_file.enabled then ripgrep_c.backend.ripgrep.max_filesize = extra_c.big_file.big_file_total or nil end
  ripgrep_c.project_root_marker = extra_c.root_markers or nil
  return spec
end, M.clear)

return M
