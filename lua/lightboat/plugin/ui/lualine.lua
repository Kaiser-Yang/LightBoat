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

local sections = {
  lualine_a = { 'progress', 'location' },
  lualine_b = {
    { 'branch', fmt = M.disable_in_ft_wrap('dap') },
    { 'diff', fmt = M.disable_in_ft_wrap('dap') },
    {
      function()
        -- PERF: performance issue for large files
        if big_file.is_big_file() then return '' end
        local last_search = vim.fn.getreg('/')
        if not last_search or last_search == '' then return '' end
        local searchcount = vim.fn.searchcount({ maxcount = 9999 })
        return last_search .. '[' .. searchcount.current .. '/' .. searchcount.total .. ']'
      end,
    },
  },
  lualine_c = {},
  lualine_x = { 'copilot', { 'filetype', fmt = M.disable_in_ft_wrap('dap') } },
  lualine_y = { 'quickfix' },
  lualine_z = { 'filename' },
}

local spec = {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons', 'AndreM222/copilot-lualine' },
  lazy = false,
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
    tabline = {},
    extensions = {},
  },
}

function M.clear() end

function M.spec() return spec end

M.setup = util.setup_check_wrap('lightboat.plugin.ui.lualine', function() return spec end, M.clear)

return M
