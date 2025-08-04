local util = require('lightboat.util')

local cofig = require('lightboat.config')
local c
local group
local M = {}

local refresh_project_config = function(show_info)
  local project_config_dir = vim.fn.getcwd() .. '/.nvim'
  -- source all the lua files in the project config directory
  local files = vim.fn.globpath(project_config_dir, '*.lua', false, true)
  table.sort(files)
  for _, file in ipairs(files) do
    if vim.fn.filereadable(file) == 1 then
      local ok, err = pcall(function() vim.cmd('source ' .. file) end)
      if not ok then
        vim.notify('Error sourcing file: ' .. file .. '\n' .. err, vim.log.levels.ERROR)
        return false
      elseif show_info then
        vim.notify('Sourced file: ' .. file, vim.log.levels.INFO)
      end
    else
      vim.notify('File not readable: ' .. file, vim.log.levels.WARN)
      return false
    end
    return true
  end
end

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  if c.enabled then vim.api.nvim_del_user_command('RefreshProjectConfig') end
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.extra.project', function()
  c = cofig.get().extra.project
  if not c.enabled then return end
  group = vim.api.nvim_create_augroup('LightBoatProject', {})

  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    callback = function() refresh_project_config(false) end,
    once = true,
  })
  vim.api.nvim_create_user_command('RefreshProjectConfig', function() refresh_project_config(true) end, {})
end, M.clear)

return M
