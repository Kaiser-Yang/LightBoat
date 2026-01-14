local util = require('lightboat.util')
local big_file = require('lightboat.extra.big_file')
local M = {}

--- @param ft_list string|string[]
function M.disable_in_ft_wrap(ft_list)
  ft_list = type(ft_list) == 'string' and { ft_list } or ft_list
  return function(str)
    assert(type(ft_list) == 'table', 'Expected a table, got: ' .. type(ft_list))
    for _, f in ipairs(ft_list) do
      if vim.bo.filetype:match(f) then return '' end
    end
    return str
  end
end

function M.search_count()
  local last_search = vim.fn.getreg('/')
  -- PERF: performance issue for large files
  if big_file.is_big_file() or vim.v.hlsearch == 0 then return last_search end
  local limit, timeout = 99, 50
  local ok, result = pcall(vim.fn.searchcount, { maxcount = limit + 1, timeout = timeout })
  if not ok or next(result) == nil then return '' end
  if result.current > limit then result.current = '??' end
  if result.total > limit then result.total = '>' .. limit end
  return last_search .. '[' .. result.current .. '/' .. result.total .. ']'
end

local sections = {
  lualine_a = {
    { 'progress', fmt = M.disable_in_ft_wrap('dap') },
    { 'location', fmt = M.disable_in_ft_wrap('dap') },
    { 'mode', fmt = M.disable_in_ft_wrap('dap') },
  },
  lualine_b = {
    { 'branch', fmt = M.disable_in_ft_wrap('dap') },
    { 'diff', fmt = M.disable_in_ft_wrap('dap') },
    { M.search_count, fmt = M.disable_in_ft_wrap('dap') },
  },
  lualine_c = {},
  lualine_x = { { 'copilot', fmt = M.disable_in_ft_wrap('dap') }, { 'filetype', fmt = M.disable_in_ft_wrap('dap') } },
  lualine_y = { 'quickfix' },
  lualine_z = { 'filename' },
}

local spec = {
  {
    'AndreM222/copilot-lualine',
    cond = not vim.g.vscode,
    enabled = vim.fn.executable('node') == 1 and vim.fn.executable('curl') == 1,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cond = not vim.g.vscode,
    opts = {
      options = {
        icons_enabled = true,
        theme = 'catppuccin',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
          'neo-tree',
          'Avante',
          'AvanteInput',
          'help',
        },
        globalstatus = false,
      },
      sections = sections,
      inactive_sections = sections,
    },
  },
}

function M.clear() end

function M.spec() return spec end

M.setup = util.setup_check_wrap('lightboat.plugin.ui.lualine', function() return spec end, M.clear)

return M
