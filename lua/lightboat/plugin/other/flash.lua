local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local flash_indirect = {
  ['f'] = '<f33>',
  ['t'] = '<f34>',
  ['F'] = '<f35>',
  ['T'] = '<f36>',
}
vim.g.flash_keys = {
  ['<f33>'] = 'f',
  ['<f34>'] = 't',
  ['<f35>'] = 'F',
  ['<f36>'] = 'T',
}
local rep_move = require('lightboat.extra.rep_move')
local prev_flash_find, next_flash_find = rep_move.make(flash_indirect['F'], flash_indirect['f'])
local prev_flash_till, next_flash_till = rep_move.make(flash_indirect['T'], flash_indirect['t'])
local big_file_check_wrap = require('lightboat.extra.big_file').big_file_check_wrap

local M = {}

local operation = {
  ['F'] = prev_flash_find,
  ['f'] = next_flash_find,
  ['T'] = prev_flash_till,
  ['t'] = next_flash_till,
  ['<c-s>'] = big_file_check_wrap(function()
    local flash = require('flash')
    local function format(opts)
      -- always show first and second label
      return {
        { opts.match.label1, 'FlashMatch' },
        { opts.match.label2, 'FlashLabel' },
      }
    end
    local first_visible_line = vim.fn.line('w0')
    local last_visible_line = vim.fn.line('w$')
    flash.jump({
      search = { mode = 'search' },
      label = {
        after = false,
        before = { 0, 0 },
        uppercase = false,
        format = format,
      },
      pattern = [[\%<]] .. last_visible_line + 1 .. 'l' .. [[\%>]] .. first_visible_line - 1 .. 'l' .. [[\<]],
      action = function(match, state)
        state:hide()
        flash.jump({
          search = { max_length = 0 },
          highlight = { matches = false },
          label = { format = format },
          matcher = function(win)
            -- limit matches to the current label
            return vim.tbl_filter(function(m) return m.label == match.label and m.win == win end, state.results)
          end,
          labeler = function(matches)
            for _, m in ipairs(matches) do
              m.label = m.label2 -- use the second label
            end
          end,
        })
      end,
      labeler = function(matches, state)
        local labels = state:labels()
        for m, match in ipairs(matches) do
          match.label1 = labels[math.floor((m - 1) / #labels) + 1]
          match.label2 = labels[(m - 1) % #labels + 1]
          match.label = match.label1
        end
      end,
    })
  end),
}

local spec = {
  'Kaiser-Yang/flash.nvim',
  branch = 'develop',
  opts = {
    search = {
      exclude = {
        'notify',
        'cmp_menu',
        'noice',
        'flash_prompt',
        'blink-cmp-menu',
        'neo-tree',
        function(win) return not vim.api.nvim_win_get_config(win).focusable end,
      },
    },
    modes = {
      char = {
        jump_labels = true,
        multi_line = false,
        char_actions = function() return { [';'] = 'next', [','] = 'prev' } end,
        jump = { do_first_jump = true, autojump = true },
        label = { exclude = 'hHjJklLiIaArRdDcCgGyY' },
        keys = flash_indirect,
      },
      search = { highlight = { backdrop = true } },
    },
    jump = { nohlsearch = true },
  },
  keys = {},
}

function M.clear()
  spec.keys = {}
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.plugin.other.flash', function()
  c = config.get().flash
  if not c.enabled then return nil end
  spec.keys = util.key.get_lazy_keys(operation, c.keys)
  return spec
end, M.clear)

return M
