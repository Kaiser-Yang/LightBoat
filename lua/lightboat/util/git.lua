local M = {}

local group

local git_repo_detector
local git_conflict_detector
local started = false

local function start_git_repo_detection()
  if not M.is_git_repository() then return end
  vim.schedule(function()
    vim.api.nvim_exec_autocmds('User', { pattern = 'GitRepoDetected' })
    if git_repo_detector then
      vim.api.nvim_del_augroup_by_id(git_repo_detector)
      git_repo_detector = nil
    end
  end)
end

local function start_git_conflict_detection()
  if not M.is_git_repository() then return end
  local cmd = {
    'git',
    'diff',
    '--quiet',
    '--diff-filter=U',
  }
  local opts = {
    stdout = false,
    stderr = false,
    cwd = vim.fn.getcwd(),
  }
  --- @param out vim.SystemCompleted
  local callback = function(out)
    if out.code ~= 1 then return end
    vim.schedule(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'GitConflictDetected' })
      if git_conflict_detector then
        vim.api.nvim_del_augroup_by_id(git_conflict_detector)
        git_conflict_detector = out
      end
    end)
  end
  vim.system(cmd, opts, callback)
  -- Check for buffer's directory once more
  local buf_dir = vim.fn.expand('%:h')
  if buf_dir ~= opts.cwd then
    opts.cmd = buf_dir
    vim.system(cmd, opts, callback)
  end
end

--- Detect some git related information, such as git repository, git conflict, etc.
--- This function only works once. Each event will be triggered only once.
--- This is used to lazy load some git related plugins, such as gitsigns, diffview, etc.
function M.detect()
  if vim.fn.executable('git') == 0 then return end
  if started then return end
  started = true
  -- Detect once for the current directory
  start_git_repo_detection()
  git_repo_detector = vim.api.nvim_create_augroup('LightBoatGitRepoDetector', {})
  vim.api.nvim_create_autocmd({ 'BufReadPre', 'DirChanged' }, {
    group = group,
    callback = start_git_repo_detection,
  })
  start_git_conflict_detection()
  git_conflict_detector = vim.api.nvim_create_augroup('LightBoatGitConflictDetector', {})
  vim.api.nvim_create_autocmd({ 'BufReadPre', 'DirChanged' }, {
    group = git_conflict_detector,
    callback = start_git_conflict_detection,
  })
end

--- @param buffer? integer
--- @param window? integer
function M.is_git_repository(buffer, window)
  return vim.fs.root(buffer or 0, '.git') ~= nil or vim.fs.root(vim.fn.getcwd(window), '.git')
end

return M
