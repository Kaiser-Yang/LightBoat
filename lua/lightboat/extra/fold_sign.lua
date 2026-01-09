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

local sign_group = 'LightBoatFoldSignSignGroup'
local function update_range(buf, first, last)
  -- do not handle invisible buffers
  if not c.buffer.is_visible_buffer(buf) then
    fold_sign_cache[buf] = nil
    return
  end
  fold_sign_cache[buf] = util.ensure_list(fold_sign_cache[buf])
  local cache = fold_sign_cache[buf]
  local last_fold_end
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
    else
      -- Remove sign if it is no longer needed
      if prev and prev.sign_id then vim.fn.sign_unplace(sign_group, { buffer = buf, id = prev.sign_id }) end
      cache[lnum] = nil
    end
  end
end

function M.update_fold_signs(buf)
  if not c or not c.fold_sign.enabled or vim.g.vscode then return end
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

--- Get all fold start line of current buffer.
--- @param fold_start number The line number of a fold start
--- @return number[], number[] A list of fold start lines, and levels of those folds
local function get_fold_start(fold_start)
  local cur_fold_end = vim.fn.foldclosedend(fold_start)
  local open = {}
  if cur_fold_end == -1 then
    open[fold_start] = true
    vim.cmd(fold_start .. 'foldclose')
    cur_fold_end = vim.fn.foldclosedend(fold_start)
    vim.cmd(fold_start .. 'foldopen')
  else
    open[fold_start] = false
    vim.cmd(fold_start .. 'foldopen')
  end
  local last_fold_end
  local res = { fold_start }
  local lvl = { 0 }
  local current_lvl = 0
  for line = fold_start + 1, cur_fold_end - 1 do
    local fold_lvl = vim.fn.foldlevel(line)
    if fold_lvl <= 0 then goto continue end
    local closed = vim.fn.foldclosed(line) == line
    if not closed then vim.cmd(line .. 'foldclose') end
    local fold_end = vim.fn.foldclosedend(line)
    if
      fold_lvl > vim.fn.foldlevel(line - 1)
      or fold_lvl == vim.fn.foldlevel(line - 1) and last_fold_end and line > last_fold_end
    then
      table.insert(res, line)
      if not last_fold_end or fold_end < last_fold_end then
        current_lvl = current_lvl + 1
      elseif fold_end > last_fold_end and res[#res] < last_fold_end then
        current_lvl = current_lvl - 1
      end
      table.insert(lvl, current_lvl)
      open[line] = not closed
    end
    last_fold_end = fold_end
    vim.cmd(line .. 'foldopen')
    ::continue::
  end
  -- Restore the fold state of the start line
  for i = #res, 1, -1 do
    if not open[res[i]] then vim.cmd(res[i] .. 'foldclose') end
  end
  return res, lvl
end

local function level_fold(line, open)
  line = line or vim.fn.line('.')
  local fold_start, fold_lvl = get_fold_start(line)
  if not open then
    fold_start = util.reverse_list(fold_start)
    fold_lvl = util.reverse_list(fold_lvl)
  end
  local level
  for i, lnum in ipairs(fold_start) do
    local fold_closed = vim.fn.foldclosed(lnum)
    local closed = fold_closed == lnum or i == 1 and fold_closed ~= -1 and fold_closed < lnum
    if open then
      if closed and (not level or level == fold_lvl[i]) then
        level = fold_lvl[i]
        vim.cmd(lnum .. 'foldopen')
      end
    else
      if not closed and (not level or level == fold_lvl[i]) then
        level = fold_lvl[i]
        vim.cmd(lnum .. 'foldclose')
      end
    end
  end
end

function M.fold_more(line)
  level_fold(line, false)
  vim.schedule(function() M.update_fold_signs(vim.api.nvim_get_current_buf()) end)
end

function M.fold_less(line)
  level_fold(line, true)
  vim.schedule(function() M.update_fold_signs(vim.api.nvim_get_current_buf()) end)
end

function M.toggle_recursively(line)
  line = line or vim.fn.line('.')
  local cur_fold_end = vim.fn.foldclosedend(line)
  if cur_fold_end == -1 then
    M.close_recursively(line)
  else
    M.open_recursively(line)
  end
  vim.schedule(function() M.update_fold_signs(vim.api.nvim_get_current_buf()) end)
end

function M.open_recursively(line)
  line = line or vim.fn.line('.')
  for _, lnum in ipairs(get_fold_start(line)) do
    if vim.fn.foldclosed(lnum) ~= -1 then vim.cmd(lnum .. 'foldopen') end
  end
  vim.schedule(function() M.update_fold_signs(vim.api.nvim_get_current_buf()) end)
end

function M.close_recursively(line)
  line = line or vim.fn.line('.')
  local fold_start = get_fold_start(line)
  -- reverse the order to close from the bottom up
  table.sort(fold_start, function(a, b) return a > b end)
  for _, lnum in ipairs(fold_start) do
    if vim.fn.foldclosed(lnum) == -1 then vim.cmd(lnum .. 'foldclose') end
  end
  vim.schedule(function() M.update_fold_signs(vim.api.nvim_get_current_buf()) end)
end

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  c = nil
end

local operation = {
  za = function()
    vim.schedule(M.update_fold_signs)
    return 'za'
  end,
  zc = function()
    vim.schedule(M.update_fold_signs)
    return 'zc'
  end,
  zo = function()
    vim.schedule(M.update_fold_signs)
    return 'zo'
  end,
  zf = function()
    vim.schedule(M.update_fold_signs)
    return 'zf'
  end,
  zd = function()
    vim.schedule(M.update_fold_signs)
    return 'zd'
  end,
  zR = function()
    vim.schedule(M.update_fold_signs)
    return 'zR'
  end,
  zM = function()
    vim.schedule(M.update_fold_signs)
    return 'zM'
  end,
  zE = function()
    vim.schedule(M.update_fold_signs)
    return 'zE'
  end,
  zC = M.close_recursively,
  zO = M.open_recursively,
  zA = M.toggle_recursively,
  zD = function()
    vim.schedule(M.update_fold_signs)
    return 'zD'
  end,
  zr = M.fold_less,
  zm = M.fold_more,
}

M.setup = util.setup_check_wrap('lightboat.extra.fold_sign', function()
  c = config.get().extra
  if not c.fold_sign.enabled then return end
  util.key.set_keys(operation, c.fold_sign.keys)
  if vim.g.vscode then return end
  group = vim.api.nvim_create_augroup('LightBoatFoldSign', {})
  util.set_hls({
    { 0, 'FoldOpen', { fg = '#89b4fa' } },
    { 0, 'FoldClosed', { fg = '#89b4fa' } },
  })
  util.define_signs({
    { 'FoldOpen', { text = '', texthl = 'FoldOpen' } },
    { 'FoldClosed', { text = '', texthl = 'FoldClosed' } },
  })
  vim.api.nvim_create_autocmd({
    'BufEnter',
    'CursorHold',
    'WinScrolled',
    'BufWritePost',
  }, {
    group = group,
    callback = function(ev)
      if ev.file == '' or not c.buffer.is_visible_buffer(ev.buf) then return end
      if vim.fn.mode('1') == 'i' then return end
      vim.defer_fn(function() M.update_fold_signs(ev.buf) end, 20)
    end,
  })
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args) fold_sign_cache[args.buf] = nil end,
  })
end, M.clear)

return M
