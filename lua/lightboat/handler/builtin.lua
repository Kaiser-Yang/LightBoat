local M = {}
local u = require('lightboat.util')
local c = require('lightboat.condition')
local repmove_available = c():plugin_available('repmove.nvim')

function M.cursor_to_eol_insert()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  if col == #line then return false end
  local last_non_blank = #(line:match('^(.-)%s*$') or '')
  if col >= last_non_blank then last_non_blank = #line end
  return string.rep('<c-g>U<right>', last_non_blank - col)
end

function M.cursor_to_eol_command()
  local line = vim.fn.getcmdline()
  local col0 = vim.fn.getcmdpos() - 1 -- 0-based
  if col0 == #line then return false end
  local last_non_blank = #(line:match('^(.-)%s*$') or '')
  if col0 >= last_non_blank then last_non_blank = #line end
  return vim.fn.setcmdline(line, last_non_blank + 1) == 0
end

function M.delete_to_eow_insert()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local line_number = vim.api.nvim_buf_line_count(0)
  if row == line_number and col == #line then return false end
  vim.bo.undolevels = vim.bo.undolevels
  vim.cmd('normal! de')
  return true
end

function M.delete_to_eow_command()
  local line = vim.fn.getcmdline()
  local col0 = vim.fn.getcmdpos() - 1 -- 0-based
  if col0 == #line then return false end

  local word_pattern = '\\k\\+' -- Vim regex: keyword sequence
  local after = line:sub(col0 + 1)
  local m = vim.fn.matchstrpos(after, word_pattern)
  local start_idx = m[2]
  local end_idx = m[3]

  local new_after
  if start_idx == -1 then
    new_after = ''
  else
    new_after = after:sub(end_idx + 1) or ''
  end
  local new_line = (line:sub(1, col0) or '') .. new_after
  return vim.fn.setcmdline(new_line, col0 + 1) == 0
end

function M.cursor_to_bol_insert()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == 0 then return false end
  local first_non_blank = #(line:match('^%s*') or '')
  if col <= first_non_blank then first_non_blank = 0 end
  return string.rep('<c-g>U<left>', col - first_non_blank)
end

local format = { '^:', '^/', '^%?', '^:%s*!', '^:%s*lua%s+', '^:%s*lua%s*=%s*', '^:%s*=%s*', '^:%s*he?l?p?%s+', '^=' }
function M.cursor_to_bol_command()
  local line = vim.fn.getcmdtype() .. vim.fn.getcmdline()
  local matched = nil
  for _, p in pairs(format) do
    local cur_matched = line:match(p)
    if not matched or cur_matched and #cur_matched > #matched then matched = cur_matched end
  end
  local col = vim.fn.getcmdpos()
  if col <= 1 then
    return false
  else
    if not matched or col <= #matched then
      vim.fn.setcmdline(line:sub(2), 1)
    else
      vim.fn.setcmdline(line:sub(2), #matched)
    end
  end
  return true
end

function M.delete_to_eol_command()
  local line = vim.fn.getcmdline()
  local col0 = vim.fn.getcmdpos() - 1 -- 0-based
  if col0 == #line then return false end
  local last_non_blank = #(line:match('^(.-)%s*$') or '')
  if col0 >= last_non_blank then last_non_blank = #line end
  local new_line = line:sub(1, col0) .. line:sub(last_non_blank + 1)
  return vim.fn.setcmdline(new_line, col0 + 1) == 0
end

function M.delete_to_eol_insert()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == #line then return false end
  local last_non_blank = #(line:match('^(.-)%s*$') or '')
  if col >= last_non_blank then last_non_blank = #line end
  vim.bo.undolevels = vim.bo.undolevels
  return string.rep('<del>', last_non_blank - col)
end

return M
