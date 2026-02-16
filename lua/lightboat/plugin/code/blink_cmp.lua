local util = require('lightboat.util')
local network = util.network
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
  {
    'saghen/blink.cmp',
    opts = {
      sources = {
        providers = {
          git = { name = 'Git', module = 'blink-cmp-git', opts = blink_cmp_git_opts },
        },
      },
    },
  },
}

M.setup = util.setup_check_wrap('lightboat.extra.blink_cmp', function()
  if vim.g.vscode then return vim.deepcopy(spec) end
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
  if vim.fn.executable('node') == 1 then
    spec[#spec].opts.sources.providers.avante = { name = 'Avante', module = 'blink-cmp-avante' }
  end
end, M.clear)

return M
