local M = {}
local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local group

--- @class FoldSignCache
--- @field fold string? The name of the fold sign
--- @field sign_id number? The ID of the sign placed in the buffer
local fold_sign_cache = {}

--- @param a number Must greater than or equal to zero
--- @param b number Must greater than or equal to zero
local function cantor_pair(a, b) return (a + b) * (a + b + 1) / 2 + b end

local function update_range(buf, first, last)
  -- do not handle invisible buffers
  if not c.fold_sign.enabled or not c.buffer.is_visible_buffer(buf) then
    fold_sign_cache[buf] = nil
    return
  end
  fold_sign_cache[buf] = util.ensure_list(fold_sign_cache[buf])
  local cache = fold_sign_cache[buf]
  local last_fold_end
  local sign_group = 'LightBoatFoldSignSignGroup'
  for lnum = first, last do
    local fold_lvl = vim.fn.foldlevel(lnum)
    local sign_name
    -- Calculate the new fold status and sign name
    if fold_lvl > 0 then
      local closed = vim.fn.foldclosed(lnum) == lnum
      if closed then
        sign_name = 'FoldClosed'
      elseif
        vim.fn.foldclosed(lnum) == -1
        and (
          fold_lvl > vim.fn.foldlevel(lnum - 1)
          or fold_lvl == vim.fn.foldlevel(lnum - 1) and last_fold_end and lnum > last_fold_end
        )
      then
        sign_name = 'FoldOpen'
      end
      last_fold_end = vim.fn.foldclosedend(lnum)
      if last_fold_end == -1 then
        vim.cmd(lnum .. 'foldclose')
        last_fold_end = vim.fn.foldclosedend(lnum)
        vim.cmd(lnum .. 'foldopen')
      end
    end

    local prev = cache[lnum]
    if sign_name then
      if not prev or prev.fold ~= sign_name then
        -- Remove previous sign if it exists
        if prev and prev.sign_id then vim.fn.sign_unplace(sign_group, { buffer = buf, id = prev.sign_id }) end
        local id = cantor_pair(buf, lnum)
        assert(id and sign_name)
        local sign_id = vim.fn.sign_place(id, sign_group, sign_name, buf, { lnum = lnum, priority = 1000 })
        if id == sign_id then
          cache[lnum] = { fold = sign_name, sign_id = id }
        else
          cache[lnum] = nil
        end
      end
    else
      -- Remove sign if it is no longer needed
      if prev and prev.sign_id then vim.fn.sign_unplace(sign_group, { buffer = buf, id = prev.sign_id }) end
      cache[lnum] = nil
    end
  end
end

function M.update_fold_signs(buf)
  buf = buf or 0
  if buf == 0 then buf = vim.api.nvim_get_current_buf() end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      local first_visible_line = vim.fn.line('w0', win)
      local last_visible_line = vim.fn.line('w$', win)
      update_range(buf, first_visible_line, last_visible_line)
    end
  end
end

-- TODO: support any line number
--- Get all fold start line of current buffer. After this function, all the fold will be opened
--- @param fold_start number The line number of a fold start
function M.get_fold_start(fold_start)
  local cur_fold_end = vim.fn.foldclosedend(fold_start)
  if cur_fold_end == -1 then
    vim.cmd(fold_start .. 'foldclose')
    cur_fold_end = vim.fn.foldclosedend(fold_start)
    vim.cmd(fold_start .. 'foldopen')
  else
    vim.cmd(fold_start .. 'foldopen')
  end
  local last_fold_end
  local res = { fold_start }
  for line = fold_start + 1, cur_fold_end - 1 do
    local fold_lvl = vim.fn.foldlevel(line)
    if fold_lvl <= 0 then goto continue end
    local closed = vim.fn.foldclosed(line) == line
    if closed then vim.cmd(line .. 'foldopen') end
    if
      fold_lvl > vim.fn.foldlevel(line - 1)
      or fold_lvl == vim.fn.foldlevel(line - 1) and last_fold_end and line > last_fold_end
    then
      table.insert(res, line)
    end
    vim.cmd(line .. 'foldclose')
    last_fold_end = vim.fn.foldclosedend(line)
    vim.cmd(line .. 'foldopen')
    ::continue::
  end
  return res
end

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.extra.fold_sign', function()
  c = config.get().extra
  if not c.fold_sign.enabled then return end
  group = vim.api.nvim_create_augroup('LightBoatFoldSign', {})
end, M.clear)

return M
