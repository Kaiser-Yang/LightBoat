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
  local start = completion_list.context.bounds.start_col
  local len = completion_list.context.bounds.length
  local input_str = completion_list.context.line:sub(start, start + len - 1)
  -- INFO:
  -- Use <cr> to accept snippets or file paths when matching the input
  if
    first
    and first.label:sub(1, #input_str) == input_str
    and (first.kind == snippet_kind or first.source_name == 'Cmdline' and vim.fn.getcmdcompltype() == 'file')
  then
    return cmp.accept({ index = 1 })
  end
end

function M.default_sources()
  local res = { 'lsp', 'path', 'snippets', 'buffer' }
  if vim.bo.filetype == 'AvanteInput' then
    table.insert(res, 'avante')
  elseif vim.tbl_contains({ 'gitcommit', 'octo' }, vim.bo.filetype) and network.status() then
    table.insert(res, 'git')
  end
  if
    vim.tbl_contains({ 'markdown', 'gitcommit', 'text', 'Avante', 'AvanteInput', 'octo' }, vim.bo.filetype)
    or util.inside_block({ 'comment', 'string' }) ~= false
  then
    vim.list_extend(res, { 'dictionary' })
    if vim.fn.executable('rg') == 1 then vim.list_extend(res, { 'ripgrep' }) end
  end
  return res
end

local operation = {
  ['<c-s>'] = { 'show_signature', 'hide_signature', 'fallback' },
  ['<cr>'] = { 'accept', 'fallback' },
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
  { 'Kaiser-Yang/blink-cmp-git', cond = not vim.g.vscode, lazy = true },
  { 'Kaiser-Yang/blink-cmp-avante', cond = not vim.g.vscode, lazy = true, enabled = vim.fn.executable('node') == 1 },
  { 'Kaiser-Yang/blink-cmp-dictionary', cond = not vim.g.vscode, dependencies = 'nvim-lua/plenary.nvim', lazy = true },
  { 'mikavilpas/blink-ripgrep.nvim', cond = not vim.g.vscode, lazy = true, enabled = vim.fn.executable('rg') == 1 },
  {
    'saghen/blink.cmp',
    cond = not vim.g.vscode,
    dependencies = { { 'rafamadriz/friendly-snippets', cond = not vim.g.vscode } },
    version = '*',
    event = { 'InsertEnter', 'CmdlineEnter' },
    opts = {
      fuzzy = { frecency = { enabled = false } },
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
            align_to = 'cursor',
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
          buffer = {
            enabled = function() return not require('lightboat.extra.big_file').is_big_file() end,
            -- keep case of first char
            -- or make all upper case
            transform_items = function(context, items)
              -- Do not convert case when searching
              if context.mode == 'cmdline' then return items end
              --- @type string
              local keyword = context.get_keyword()
              local case
              if keyword:match('^%l') then
                case = string.lower
              -- TODO:
              -- this does not work, because the length of keyword will always be 1 for buffer source
              elseif keyword:match('^%u%u') then
                case = string.upper
              elseif not keyword:match('^%u') then
                return items
              end
              local out = {}
              for _, item in ipairs(items) do
                local raw = item.insertText
                local text = (case ~= nil and case(raw) or (string.upper(raw:sub(1, 1)) .. string.lower(raw:sub(2))))
                -- We only adjust the case of the first char when there is no capital letters.
                if raw:match('[A-Z]') then text = raw end
                item.insertText = text
                item.label = text
                table.insert(out, item)
              end
              return out
            end,
          },
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
        },
      },
    },
    config = function(_, opts)
      require('blink.cmp').setup(opts)
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
        for id in vim.iter({ 'lsp', 'dictionary', 'buffer', 'ripgrep' }) do
          items_by_source[id] = items_by_source[id] and vim.iter(items_by_source[id]):filter(filter):totable()
        end
        return original(ctx, items_by_source)
      end
    end,
    opts_extend = { 'sources.default' },
  },
}

-- HACK:
-- This is not a good way to expose spec, need to find a better way
function M.spec() return vim.deepcopy(spec) end

function M.clear()
  assert(spec[#spec][1] == 'saghen/blink.cmp')
  spec[#spec].opts.sources.providers.avante = nil
  spec[#spec].opts.sources.providers.ripgrep = nil
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.extra.blink_cmp', function()
  if vim.g.vscode then return vim.deepcopy(spec) end
  c = config.get().blink_cmp
  for _, s in ipairs(spec) do
    s.enabled = c.enabled
  end
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
  if vim.fn.executable('node') == 1 then
    spec[#spec].opts.sources.providers.avante = { name = 'Avante', module = 'blink-cmp-avante' }
  end
  if vim.fn.executable('rg') == 1 then
    local extra_c = config.get().extra
    spec[#spec].opts.sources.providers.ripgrep = {
      name = 'RG',
      module = 'blink-ripgrep',
      opts = {
        prefix_min_len = 3,
        project_root_marker = extra_c.root_markers or nil,
        fallback_to_regex_highlighting = true,
        backend = {
          context_size = 5,
          project_root_fallback = false,
          ripgrep = {
            max_filesize = extra_c.big_file.enabled and extra_c.big_file.big_file_total or nil,
            search_casing = '--smart-case',
            additional_rg_options = { '--max-count', '5' },
          },
        },
      },
    }
  end
  for k, v in pairs(c.keys) do
    if not v or not operation[k] then goto continue end
    spec[#spec].opts.keymap[v.key] = operation[k]
    if vim.tbl_contains({ '<cr>', '<c-j>', '<c-k>' }, k) then spec[#spec].opts.cmdline.keymap[v.key] = operation[k] end
    if k == '<tab>' then
      spec[#spec].opts.cmdline.keymap[v.key] = { function(cmp) return cmp.accept({ index = 1 }) end }
    end
    ::continue::
  end
  return vim.deepcopy(spec)
end, M.clear)

return M
