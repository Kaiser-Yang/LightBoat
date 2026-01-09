local util = require('lightboat.util')
local lfu = util.lfu
local lru = util.lru
local config = require('lightboat.config')
local c
local M = {}
local buffer_cache
local group

--- Get a list of all visible buffers.
--- A visible buffer is one that is valid and listed.
--- @return number[] A list of visible buffer numbers.
local function get_visible_bufs()
  local res = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if c and c.is_visible_buffer(buf) then table.insert(res, buf) end
  end
  return res
end

local function quit(buf)
  buf = util.buffer.normalize_buf(buf)
  if vim.bo[buf].buftype ~= '' then
    vim.cmd('q')
    return
  end
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local tabs = vim.api.nvim_list_tabpages()
  local cur_win = vim.api.nvim_get_current_win()
  local cur_tab = vim.api.nvim_get_current_tabpage()
  local hold_by_other
  local cur_tab_visible_bufs = {}
  for _, tab in pairs(tabs) do
    for _, win in pairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local win_buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[win_buf].filetype == 'DiffviewFiles' then
        vim.cmd('DiffviewClose')
        return
      elseif vim.bo[win_buf].filetype == 'gitcommit' then
        vim.cmd('tabclose')
        return
      end
      if win_buf == buf and win ~= cur_win then hold_by_other = true end
      if c.is_visible_buffer(win_buf) and tab == cur_tab then table.insert(cur_tab_visible_bufs, win_buf) end
    end
  end
  local visible_bufs = get_visible_bufs()
  local function get_target_buf(visible)
    local res
    for _, b in pairs(visible_bufs) do
      if b == buf or not visible and vim.tbl_contains(cur_tab_visible_bufs, b) then goto continue end
      if not vim.api.nvim_buf_is_valid(b) then
        buffer_cache:del(b)
        goto continue
      end
      if not res then
        res = b
        goto continue
      end
      if buffer_cache:last_vis(res) < buffer_cache:last_vis(b) then res = b end
      ::continue::
    end
    return res
  end
  --- @param cmd string
  --- @param args string[]
  local function safe_command(cmd, args)
    local res = vim.api.nvim_cmd({
      cmd = cmd,
      args = args,
      bang = false, -- do not add a bang to the command
    }, { output = true })
    local error = not res:match('^%s*$')
    return error and res or nil
  end
  local function try_to_bd()
    if hold_by_other then return end
    vim.api.nvim_buf_delete(buf, { force = false, unload = false })
  end
  if not c.is_visible_buffer(buf) then
    local target_win
    local target_buffer = get_target_buf(true)
    if target_buffer then
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local win_buf = vim.api.nvim_win_get_buf(win)
        if win_buf == target_buffer then
          target_win = win
          break
        end
      end
    end
    if target_win then vim.api.nvim_set_current_win(target_win) end
    vim.api.nvim_win_close(cur_win, false)
    try_to_bd()
    return
  elseif #tabs > 1 and #cur_tab_visible_bufs <= 1 then
    if safe_command('tabclose', {}) then try_to_bd() end
    return
  elseif #visible_bufs <= 1 then
    if not hold_by_other then
      vim.cmd('qa')
    else
      vim.cmd('q')
    end
    return
  end
  local target_buffer = get_target_buf()
  assert(not vim.tbl_contains(cur_tab_visible_bufs, target_buffer), 'target_buf should not be visible')
  if target_buffer then
    vim.api.nvim_win_set_buf(cur_win, target_buffer)
  else
    vim.api.nvim_win_close(cur_win, false)
  end
  try_to_bd()
end

local operation = { Q = quit }

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  util.key.clear_keys(operation, c.keys)
  buffer_cache = nil
  c = nil
end

M.setup = util.setup_check_wrap('lightboat.extra.buffer', function()
  if vim.g.vscode then return end
  c = config.get().extra.buffer
  if not c.enabled then return end

  util.key.set_keys(operation, c.keys)
  local initial_buffers = get_visible_bufs()
  local capacity = math.max(c.visible_buffer_limit, #initial_buffers)
  buffer_cache = c.cache_type == 'lfu' and lfu.new(capacity) or lru.new(capacity)
  for _, buf in ipairs(initial_buffers) do
    buffer_cache:set(buf, true)
  end
  group = vim.api.nvim_create_augroup('LightBoatBuffer', {})
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(ev)
      if not c or not c.is_visible_buffer(ev.buf) then return end
      local visible_bufs = get_visible_bufs()
      -- This happens when failing to delete one buffer
      if buffer_cache.capacity > c.visible_buffer_limit then
        buffer_cache:set_capacity(math.max(c.visible_buffer_limit, #visible_bufs))
      end
      local should_delete = {}
      for _, buf in ipairs(visible_bufs) do
        if buf ~= ev.buf and not buffer_cache:contains(buf) then
          if buffer_cache:full() then
            should_delete[buf] = true
          else
            buffer_cache:set(buf, true)
          end
        end
      end
      local deleted_buf, _ = buffer_cache:set(ev.buf, true)
      if deleted_buf then should_delete[deleted_buf] = true end
      for buf in pairs(should_delete) do
        if not vim.api.nvim_buf_is_valid(buf) then goto continue end
        local res = vim.api.nvim_cmd({
          cmd = 'bdelete',
          args = { buf },
          bang = false, -- do not add a bang to the command
        }, { output = true })
        -- This may happen when the buffer is not saved
        local error = not res:match('^%s*$')
        if error then
          -- When we can not delete the buffer,
          -- we will just keep it in the cache
          buffer_cache:set_capacity(buffer_cache.capacity + 1)
          buffer_cache:set(buf, true)
        end
        ::continue::
      end
    end,
  })
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args) buffer_cache:del(args.buf) end,
  })
end, M.clear)

return M
