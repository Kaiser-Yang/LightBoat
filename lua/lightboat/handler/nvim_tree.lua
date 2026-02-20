local M = {}
local check = function()
  if not require('lightboat.util').plugin_available('nvim-tree.lua') then
    vim.notify('nvim-tree.lua is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end
M.copy_to = function()
  if not check() then return end
  local api = require('nvim-tree.api')
  local file_src = api.tree.get_node_under_cursor()['absolute_path']
  file_src = vim.fn.fnamemodify(file_src, ':h')
  if file_src:sub(-1) ~= '/' then file_src = file_src .. '/' end
  local input_opts = { prompt = 'Copy to ', default = file_src, completion = 'file' }

  vim.ui.input(input_opts, function(file_out)
    if not file_out or file_out == '' then return end
    local dir = vim.fn.fnamemodify(file_out, ':h')

    local res = vim.fn.system({ 'mkdir', '-p', dir })
    if vim.v.shell_error ~= 0 then
      vim.notify(res, vim.log.levels.ERROR, { title = 'Light Boat' })
      return
    end

    vim.fn.system({ 'cp', '-R', file_src, file_out })
  end)
end
M.move_to = function()
  if not check() then return end
  local api = require('nvim-tree.api')
  local file_src = api.tree.get_node_under_cursor()['absolute_path']
  file_src = vim.fn.fnamemodify(file_src, ':h')
  if file_src:sub(-1) ~= '/' then file_src = file_src .. '/' end
  local input_opts = { prompt = 'Move to ', default = file_src, completion = 'file' }

  vim.ui.input(input_opts, function(file_out)
    if not file_out or file_out == '' then return end
    local dir = vim.fn.fnamemodify(file_out, ':h')

    local res = vim.fn.system({ 'mkdir', '-p', dir })
    if vim.v.shell_error ~= 0 then
      vim.notify(res, vim.log.levels.ERROR, { title = 'NvimTree' })
      return
    end

    vim.fn.system({ 'mv', file_src, file_out })
  end)
end
M.collapse_or_go_to_parent = function()
  if not check() then return end
  local api = require('nvim-tree.api')
  local node = api.tree.get_node_under_cursor()
  if node == nil or node.parent == nil then return false end
  if node.nodes ~= nil and node.open then
    api.node.collapse()
  else
    api.node.navigate.parent()
  end
end

M.open_folder_or_preview = function()
  if not check() then return end
  local api = require('nvim-tree.api')
  local node = api.tree.get_node_under_cursor()
  if node == nil or node.parent == nil then return false end
  if node.nodes ~= nil then
    if node.open then
      return false
    else
      api.node.open.edit()
    end
  else
    api.node.open.preview()
  end
end

M.copy_node_information = function()
  if not check() then return end
  local api = require('nvim-tree.api')
  local node = api.tree.get_node_under_cursor()
  if node == nil then return false end
  local filepath = node.absolute_path
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
  vim.ui.select(options, {
    prompt = 'Copy node information',
    format_item = function(item) return ('%s: %s'):format(item, vals[item]) end,
  }, function(choice)
    if not choice or not vals[choice] then return end
    vim.fn.setreg('"', vals[choice])
    vim.fn.setreg('+', vals[choice])
    vim.notify(string.format('Copied "%s" to clipboard', vals[choice]), vim.log.levels.INFO, { title = 'Light Boat' })
  end)
end

M.change_root_to_node = function(node)
  if not check() then return end
  local api = require('nvim-tree.api')
  node = node or api.tree.get_node_under_cursor()
  if node == nil or node.absolute_path == nil or vim.fn.isdirectory(node.absolute_path) == 0 then return false end
  vim.api.nvim_set_current_dir(node.absolute_path)
  api.tree.change_root(node.absolute_path)
end

M.change_root_to_parent = function(node)
  if not check() then return end
  local api = require('nvim-tree.api')
  node = node or api.tree.get_node_under_cursor()
  if node == nil then return false end
  local new_cwd = vim.fn.fnamemodify(node.absolute_path, ':h') .. '/..'
  vim.notify(new_cwd, vim.log.levels.INFO, { title = 'Light Boat' })
  if vim.fn.isdirectory(new_cwd) == 0 then return false end
  vim.api.nvim_set_current_dir(new_cwd)
  api.tree.change_root(new_cwd)
end

local file
M.open_focus_reveal = function()
  if not check() then return end
  local tree = require('nvim-tree.api').tree
  if not tree.is_visible() then
    if vim.bo.filetype ~= 'NvimTree' then file = vim.api.nvim_buf_get_name(0) end
    tree.open()
  elseif vim.bo.filetype ~= 'NvimTree' then
    if vim.bo.filetype ~= 'NvimTree' then file = vim.api.nvim_buf_get_name(0) end
    tree.focus()
  else
    tree.find_file({ buf = file })
  end
end

return M
