local util = require('lightboat.util')
local c = require('lightboat.config').get().extra

local function has_root_directory()
  return vim.fs.root(0, c.root_markers or {}) ~= nil
end

local spec = {
  'rmagatti/auto-session',
  lazy = false,
  opts = {
    auto_save = has_root_directory,
    auto_create = has_root_directory,
    auto_restore = has_root_directory,
    git_use_branch_name = true,
    git_auto_restore_on_branch_change = true,
    continue_restore_on_error = false,
    session_lens = {
      mappings = { delete_session = false, alternate_session = false, copy_session = false },
    },
  },
}

local M = {}

function M.spec() return spec end

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.session', function() return spec end, M.clear)

return M
