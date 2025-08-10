local util = require('lightboat.util')
local diagnostic_win_id
local fold_sign = require('lightboat.extra.fold_sign')
local fts = {
  'neo-tree',
  'dapui_watches',
  'dapui_stacks',
  'dapui_breakpoints',
  'dapui_scopes',
  'dap-repl',
  'dapui_console',
  'snacks_picker_input',
  'snacks_picker_preview',
  'snacks_picker_list',
}
local spec = {
  'luukvbaal/statuscol.nvim',
  event = 'VeryLazy',
  opts = {
    segments = {
      {
        click = 'v:lua.ScSa',
        sign = {
          name = { '^[^gF]' },
          namespace = { '^[^gf]' },
          colwidth = 1,
        },
        condition = { function() return not vim.tbl_contains(fts, vim.bo.filetype) end },
      },
      {
        text = { function(args) return '%=' .. _G.get_label(args) end, ' ' },
        click = 'v:lua.ScLa',
      },
      {
        click = 'v:lua.ScSa',
        sign = {
          name = { 'FoldClosed', 'FoldOpen' },
          namespace = { 'git' },
          colwidth = 1,
        },
        condition = { function() return not vim.tbl_contains(fts, vim.bo.filetype) end },
      },
    },
    clickhandlers = {
      Lnum = function(args)
        -- <C-LeftMouse> or <RightMouse>
        if args.button == 'l' and args.mods:find('c') or args.button == 'r' and args.mods:match('^%s*$') then
          require('lightboat.plugin.code.dap').set_condition_breakpoint()
        -- <LeftMouse>
        elseif args.button == 'l' and args.mods:match('^%s*$') then
          require('dap').toggle_breakpoint()
        end
      end,
      gitsigns = function(args)
        local gitsigns = require('gitsigns')
        -- <LeftMouse>
        if args.button == 'l' and args.mods:match('^%s*$') then
          for _, winid in ipairs(vim.api.nvim_list_wins()) do
            -- Hunk is visible, we close the preview window
            if vim.w[winid].gitsigns_preview == 'hunk' then
              vim.api.nvim_win_close(winid, true)
              return
            end
          end
          gitsigns.preview_hunk()
        -- <MiddleMouse>
        elseif args.button == 'm' and args.mods:match('^%s*$') then
          gitsigns.reset_hunk()
        -- <RightMouse>
        elseif args.button == 'r' and args.mods:match('^%s*$') then
          gitsigns.stage_hunk()
        end
      end,
      ['diagnostic.signs'] = function(args)
        -- <LeftMouse>
        if args.button == 'l' and args.mods:match('^%s*$') then
          -- Hide if it is already open
          if diagnostic_win_id then
            if vim.api.nvim_win_is_valid(diagnostic_win_id) then
              vim.api.nvim_win_close(diagnostic_win_id, true)
              diagnostic_win_id = nil
              return
            end
          end
          _, diagnostic_win_id = vim.diagnostic.open_float({ border = 'rounded' })
        end
      end,
      FoldClosed = function(args)
        -- <C-LeftMouse>
        if args.button == 'l' and args.mods:find('c') then
          fold_sign.open_recursively(args.mousepos.line)
        -- <LeftMouse>
        elseif args.button == 'l' and args.mods:match('^%s*$') then
          vim.cmd('normal! zo')
          fold_sign.update_fold_signs(vim.api.nvim_get_current_buf())
        end
      end,
      FoldOpen = function(args)
        -- <C-LeftMouse>
        if args.button == 'l' and args.mods:find('c') then
          fold_sign.close_recursively(args.mousepos.line)
        -- <LeftMouse>
        elseif args.button == 'l' and args.mods:match('^%s*$') then
          vim.cmd('normal! zc')
          fold_sign.update_fold_signs(vim.api.nvim_get_current_buf())
        end
      end,
    },
  },
}

local M = {}

function M.clear() end

M.setup = util.setup_check_wrap('lightboat.plugin.ui.statuscol', function() return spec end, M.clear)

return M
