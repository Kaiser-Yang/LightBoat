local M = {}

local group

local function clear_autocmds()
  if not group then return end
  vim.api.nvim_del_augroup_by_id(group)
  group = nil
end

local function start()
  if not M.is_git_repository() then return end
  vim.schedule(function() vim.api.nvim_exec_autocmds('User', { pattern = 'GitRepoDetected' }) end)
  clear_autocmds()
end

--- Detect if the buffer is in a Git repository.
--- This function only works once. Once a git repository is detected,
--- it will not check again. When a git repository is detected,
--- it will trigger the `User GitRepoDetected` autocommand.
function M.detect()
  -- Detect once for the current directory
  start()
  group = vim.api.nvim_create_augroup('LightBoatGitDetect', {})
  vim.api.nvim_create_autocmd('BufReadPre', {
    group = group,
    callback = start,
  })
end

function M.is_git_repository(buffer) return vim.fs.root(buffer or 0, '.git') ~= nil end

return M
