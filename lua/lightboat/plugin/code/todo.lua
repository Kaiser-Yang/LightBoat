local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local group
local big_file = require('lightboat.extra.big_file')

local rep_move = require('lightboat.extra.rep_move')
local prev_todo, next_todo = rep_move.make(
  function() require('todo-comments').jump_prev() end,
  function() require('todo-comments').jump_next() end
)
local M = {}
local operation = {
  ['<leader>st'] = function()
    if not Snacks then return end
    Snacks.picker.todo_comments({
      on_show = function() vim.cmd.stopinsert() end,
    })
  end,
  [']t'] = next_todo,
  ['[t'] = prev_todo,
}
local spec = {
  'folke/todo-comments.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  event = 'VeryLazy',
  opts = {
    sign_priority = 1,
    highlight = { multiline = false },
    search = {
      command = 'rg',
      args = {
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
      },
      pattern = [[\b(KEYWORDS):]],
    },
  },
  keys = {},
}

function M.spec() return spec end

function M.clear()
  spec.keys = {}
  c = nil
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
end

M.setup = util.setup_check_wrap('lightboat.plugin.code.todo', function()
  c = config.get().todo
  if not c.enabled then return nil end
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  group = vim.api.nvim_create_augroup('LightBoatTodo', {})
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = function(ev)
      if not big_file.is_big_file(ev.buf) then return end
      local h = require('todo-comments.highlight')
      h.stop()
      h.start()
    end,
  })
  return spec
end, M.clear)

return M
