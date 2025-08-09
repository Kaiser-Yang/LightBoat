local util = require('lightboat.util')
local config = require('lightboat.config')
local group
local c
local M = {}
local operation = {
  ['<localleader>f'] = "<c-g>u<esc>/<++><cr>c4l<cmd>call histdel('/', -1)<cr>",
  ['<localleader>1'] = '<c-g>u# ',
  ['<localleader>2'] = '<c-g>u## ',
  ['<localleader>3'] = '<c-g>u### ',
  ['<localleader>4'] = '<c-g>u#### ',
  ['<localleader>a'] = '<c-g>u[](<++>)<++><esc>F[a',
  ['<localleader>b'] = '<c-g>u****<++><esc>F*hi',
  ['<localleader>c'] = '<c-g>u```<cr>```<cr><++><esc>2kA',
  ['<localleader>t'] = '<c-g>u``<++><esc>F`i',
  ['<localleader>m'] = '<c-g>u$$  $$<++><esc>F i',
  ['<localleader>d'] = '<c-g>u~~~~<++><esc>F~hi',
  ['<localleader>i'] = '<c-g>u**<++><esc>F*i',
  ['<localleader>M'] = '<c-g>u$$<cr><cr>$$<cr><++><esc>2kA',
}

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_name(group)
    group = nil
  end
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.extra.markdown', function()
  c = config.get().extra
  if not c.markdown.enabled then return end

  group = vim.api.nvim_create_augroup('LightBoatExtraMarkdown', {})
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = c.markdown_fts,
    callback = function()
      if c.markdown.enable_spell_check then vim.cmd.setlocal('spell') end
      util.key.set_keys(operation, c.markdown.keys)
    end,
  })
end, M.clear)

return M
