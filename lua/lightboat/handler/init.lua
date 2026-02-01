local util = require('lightboat.util')
--- @return boolean
local function last_key_match_local_leader()
  local last_key = util.key.last_key()
  vim.notify(vim.inspect(last_key))
  if last_key == nil then return false end
  local content_before_cursor = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
  local local_leader = vim.api.nvim_replace_termcodes(vim.g.maplocalleader, true, true, true)
  last_key = vim.api.nvim_replace_termcodes(last_key, true, true, true)
  return last_key:match(local_leader .. '$') and content_before_cursor:match(last_key .. '$')
end
---
--- @param s string
--- @return string|nil
local function local_leader_check(s)
  if last_key_match_local_leader() then return s end
end
local M = {
  --- @param n number
  --- @param filetype string|string[]
  title = function(n, filetype)
    return function()
      if vim.tbl_contains(util.ensure_list(filetype), vim.bo.filetype) then
        return local_leader_check('<c-g>u<bs>' .. string.rep('#', n) .. ' ')
      end
    end
  end,
  --- @param filetype string|string[]
  separate_line = function(filetype)
    return function()
      if vim.tbl_contains(util.ensure_list(filetype), vim.bo.filetype) then
        return local_leader_check('<c-g>u<bs>---<cr><cr>')
      end
    end
  end,
}
return M
