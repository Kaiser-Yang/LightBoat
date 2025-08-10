local util = require('lightboat.util')
local group
local M = {}
local spec = {
  'yetone/avante.nvim',
  enabled = vim.fn.executable('node') == 1,
  build = 'make',
  version = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  event = { { event = 'User', pattern = 'NetworkChecked' } },
  opts = {
    provider = 'copilot',
    autosuggestion_provider = 'copilot',
    mappings = {
      suggestion = {
        accept = '<m-cr>',
        dismiss = '<c-c>',
        next = '<c-j>',
        prev = '<c-k>',
      },
      submit = { insert = '<M-CR>' },
    },
    selector = { provider = 'snacks' },
  },
}
function M.spec() return spec end

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_name(group)
    group = nil
  end
end

M.setup = util.setup_check_wrap('lightboat.plugin.ai.avante', function()
  group = vim.api.nvim_create_augroup('LightboatAvante', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'Avante*',
    callback = function()
      if vim.bo.filetype == 'AvanteInput' then return end
      for _, key in pairs({ 'i', 'I', 'a', 'A', 'o', 'O' }) do
        util.key.set({ 'n' }, key, function()
          local win = util.buffer.get_win_with_filetype('AvanteInput')[1]
          vim.api.nvim_set_current_win(win)
        end, { buffer = true })
      end
    end,
  })
  return spec
end, M.clear)

return M
