local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local M = {}

local spec = {
  'hakonharnes/img-clip.nvim',
  enabled = (vim.fn.has('mac') and vim.fn.executable('pngpaste') == 1)
    or (vim.fn.has('linux') and (vim.fn.executable('xclip') == 1 or vim.fn.executable('wl-paste') == 1)),
  branch = 'main',
  opts = {
    default = {
      prompt_for_file_name = false,
      drag_and_drop = { enabled = true, insert_mode = true },
      dir_path = function() return 'assets/' .. vim.fn.expand('%:t') end,
      relative_to_current_file = true,
    },
    filetypes = {},
  },
}

local win_powershell_path = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/'

function M.clear()
  vim.env.PATH = vim.env.PATH:gsub(win_powershell_path .. ':', '')
  spec.ft = nil
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.markdown.img_clip', function()
  c = config.get()
  if not c.img_clip.enabled then return nil end
  spec.ft = c.extra.markdown_fts
  if c.img_clip.disable_in_gitcommit then
    spec.ft = vim.tbl_filter(function(ft) return ft ~= 'gitcommit' end, spec.ft)
  end
  if c.img_clip.init_for_wsl then
    if vim.fn.has('wsl') == 1 then
      if vim.fn.executable(win_powershell_path .. 'powershell.exe') == 1 then
        vim.env.PATH = win_powershell_path .. ':' .. vim.env.PATH
      end
    end
  end
  return spec
end, M.clear)

return M
