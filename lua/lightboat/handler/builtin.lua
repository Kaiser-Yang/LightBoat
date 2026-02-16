local M = {}
local u = require('lightboat.util')

local function toggle_comment_insert_mode()
  local commentstring = vim.bo.commentstring
  if not commentstring or commentstring:match('^%s*$') or commentstring:find('%%s') == nil then return false end

  local indent, line = vim.api.nvim_get_current_line():match('^(%s*)(.*)$')
  -- split commentstring into left and right around "%s"
  local left, right = commentstring:match('^(.-)%%s(.-)$')
  left = left or ''
  right = right or ''

  -- cursor col BEFORE change (0-indexed)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local col = cursor[2]

  -- detect if the line (after indent) is already wrapped by left and right
  local has_left = (#left == 0) or (line:sub(1, #left) == left)
  local has_right = (#right == 0) or (line:sub(-#right) == right)

  local new_line
  local shift = 0 -- desired change in column relative to original col

  if has_left and has_right then
    -- remove the surrounding left/right (toggle off)
    local content_start = #left + 1
    local content_end = #line - #right
    if content_end < content_start then
      new_line = indent
    else
      new_line = indent .. line:sub(content_start, content_end)
    end
    shift = -#left
  else
    -- add left and right around the existing content (toggle on)
    new_line = indent .. left .. line .. right
    shift = #left
  end

  -- apply the new line (this may move the cursor automatically)
  vim.api.nvim_set_current_line(new_line)

  -- compute desired column after the change, clamped to the new line length and not before indent
  local new_content_len = #new_line - #indent
  if new_content_len < 0 then new_content_len = 0 end
  local min_col = #indent
  local max_col = #indent + math.max(0, new_content_len)
  local desired_col = col
  if col >= #indent then
    desired_col = col + shift
    if desired_col < min_col then desired_col = min_col end
    if desired_col > max_col then desired_col = max_col end
  end

  -- read actual column after set_current_line
  local actual_col = vim.api.nvim_win_get_cursor(0)[2]

  local delta = desired_col - actual_col
  return string.rep(delta > 0 and '<right>' or '<left>', math.abs(delta))
end

function M.cursor_to_eol_insert()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  if col == #line then return false end
  local last_non_blank = #(line:match('^(.-)%s*$') or '')
  if col >= last_non_blank then last_non_blank = #line end
  vim.bo.undolevels = vim.bo.undolevels
  vim.api.nvim_win_set_cursor(0, { row, last_non_blank })
  return true
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
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if col == 0 then return false end
  local first_non_blank = #(line:match('^%s*') or '')
  if col <= first_non_blank then first_non_blank = 0 end
  vim.bo.undolevels = vim.bo.undolevels
  vim.api.nvim_win_set_cursor(0, { row, first_non_blank })
  return true
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
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if col == #line then return false end
  local last_non_blank = #(line:match('^(.-)%s*$') or '')
  if col >= last_non_blank then last_non_blank = #line end
  vim.bo.undolevels = vim.bo.undolevels
  if last_non_blank == #line then
    vim.cmd('normal! d$')
  else
    vim.cmd('normal! dg_')
  end
  vim.api.nvim_win_set_cursor(0, { row, col })
  return true
end

function M.system_yank()
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 2) == 'no' then
    if vim.v.operator ~= 'y' or vim.v.register ~= '+' then return false end
    return 'y'
  else
    return '"+y'
  end
end

function M.system_cut()
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 2) == 'no' then
    if vim.v.operator ~= 'd' or vim.v.register ~= '+' then return false end
    return 'd'
  else
    return '"+d'
  end
end

function M.auto_indent()
  if vim.bo.indentexpr == '' then return false end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local cur_indent = vim.fn.indent(row)
  vim.v.lnum = row
  local ok, correct_indent = pcall(vim.fn.eval, vim.bo.indentexpr)
  if not ok or cur_indent == correct_indent then return false end
  return '<c-f>'
end

-- stylua: ignore start
function M.select_file() u.update_selection(0, 0, vim.api.nvim_buf_line_count(0), 0, 'V') return true end
function M.comment() return require('vim._comment').operator() end
function M.comment_line() return require('vim._comment').operator() .. '_' end
function M.comment_line_insert() return toggle_comment_insert_mode() end
function M.comment_selection() return M.comment() end
M.system_put_command = '<c-r><c-r>+'
M.system_put_insert = '<cmd>set paste<cr><c-g>u<c-r><c-r>+<cmd>set nopaste<cr>'
M.system_put = '"+p'
M.system_put_before = '"+P'
M.system_yank_eol = '"+y$'
M.system_cut_eol = '"+d$'
-- stylua: ignore end

function M.toggle_inlay_hint()
  local status = vim.lsp.inlay_hint.is_enabled() == false
  u.toggle_notify('Inlay Hint', status, { title = 'LSP' })
  vim.lsp.inlay_hint.enable(status)
  return true
end

function M.toggle_spell()
  local status = vim.wo.spell == false
  u.toggle_notify('Spell', status, { title = 'Neovim' })
  vim.wo.spell = status
  return true
end

function M.toggle_treesitter()
  local buf = vim.api.nvim_get_current_buf()
  local status = vim.treesitter.highlighter.active[buf] == nil
  u.toggle_notify('Treesitter Highlight', status, { title = 'Treesitter' })
  if status then
    vim.treesitter.start(buf)
  else
    vim.treesitter.stop(buf)
  end
  return true
end

return M
