local config = require('lightboat.config')
local util = require('lightboat.util')
local big_file = require('lightboat.extra.big_file')
local map = util.key.set
local del = util.key.del
local feedkeys = util.key.feedkeys
local c
local M = {}
--- @type table<number, { prev: function?, next: function? }>
local last_motion = {}
local last_motion_char

vim.g.flash_keys = vim.g.flash_keys or {}

local function ensure_last_motion(buf) last_motion[buf] = last_motion[buf] or {} end

local function can_repeat(fu) return type(fu) == 'function' end

-- builtin and can be repeated by comma and semicolon
local builtin_motions = { 'F', 'f', 'T', 't' }
-- builtin but can not be repeated by comma or semicolon
local extra_builtin_motions = { 'b', 'w', 'B', 'W', 'ge', 'e', 'gE', 'E', 'N', 'n', '[s', ']s' }

--- @return function
local function value_wrap(value)
  return function() return value end
end

--- @param func function
--- @param args table
--- @param use_v_count1 boolean
local function make_extra_builtin_func(func, args, use_v_count1)
  return function()
    local res = func(unpack(args))
    return (use_v_count1 and vim.v.count1 or '') .. (res or '')
  end
end

local function macro() return #vim.fn.reg_recording() > 0 or #vim.fn.reg_executing() > 0 end

local function update_find_or_till_char()
  local ok, char = pcall(vim.fn.getcharstr)
  if ok and #char == 1 then
    local byte = string.byte(char)
    if byte >= 32 and byte <= 126 then
      -- Only record printable character
      last_motion_char = char
    end
  end
  return ok and char or nil
end

local function flash_func(key)
  return function()
    -- fallback to normal find and till
    if macro() or big_file.is_big_file() then return vim.g.flash_keys[key] end
    feedkeys(key, 'm')
    vim.schedule(function()
      local res = update_find_or_till_char()
      if not res then return end
      feedkeys(res, 'nt')
    end)
    -- case_sensitive_once()
  end
end

local function make_flash_func(key)
  -- fallback to normal ; and ,
  if macro() or big_file.is_big_file() then return nil end
  return function()
    if not last_motion_char then return end
    feedkeys(key, 'm')
    vim.schedule(function() feedkeys(last_motion_char, 'nt') end)
  end
end

--- @param a any
--- @param b any
--- @param msg string
local function assert_pair_consistency(a, b, msg) assert((a and b) or not (a or b), msg) end

--- @param tbl table
--- @param v1 any
--- @param v2 any
local function is_pair(tbl, v1, v2) return vim.tbl_contains(tbl, v1), vim.tbl_contains(tbl, v2) end

--- @param prev_func function|string
--- @param next_func function|string
--- @param reversed boolean
--- @return function
local function repeat_wrap(prev_func, next_func, reversed)
  local prev_is_builtin, next_is_builtin = is_pair(builtin_motions, prev_func, next_func)
  assert_pair_consistency(
    prev_is_builtin,
    next_is_builtin,
    'Both prev_func and next_func should be either built-in motions or custom functions.'
  )

  local prev_is_extra_builtin, next_is_extra_builtin = is_pair(extra_builtin_motions, prev_func, next_func)
  assert_pair_consistency(
    prev_is_extra_builtin,
    next_is_extra_builtin,
    'Both prev_func and next_func should be either extra built-in motions or custom functions.'
  )

  local prev_is_flash_find_till, next_is_flash_find_till = vim.g.flash_keys[prev_func], vim.g.flash_keys[next_func]
  assert_pair_consistency(
    prev_is_flash_find_till,
    next_is_flash_find_till,
    'Both prev_func and next_func should be either flash find/till motions or custom functions.'
  )

  local is_builtin = prev_is_builtin and next_is_builtin
  local is_extra_builtin = prev_is_extra_builtin and next_is_extra_builtin
  local is_flash_find_till = prev_is_flash_find_till and next_is_flash_find_till and true
  local prev_key, next_key
  if is_flash_find_till then
    prev_key = prev_func
    next_key = next_func
    prev_func = flash_func(prev_key)
    next_func = flash_func(next_key)
  end
  if type(prev_func) == 'string' then prev_func = value_wrap(prev_func) end
  if type(next_func) == 'string' then next_func = value_wrap(next_func) end
  return function(...)
    local buf = vim.api.nvim_get_current_buf()
    local args = { ... }
    if vim.tbl_contains({ 'v', 'V', 'CTRL-V', 'n' }, vim.fn.mode()) then
      if is_flash_find_till then
        assert(type(prev_key) == 'string' and type(next_key) == 'string')
        local _prev = reversed and next_key or prev_key
        local _next = reversed and prev_key or next_key
        ensure_last_motion(buf)
        last_motion[buf].prev = make_flash_func(_prev)
        last_motion[buf].next = make_flash_func(_next)
      elseif is_builtin then
        ensure_last_motion(buf)
        last_motion[buf].prev = nil
        last_motion[buf].next = nil
      else
        local _prev = reversed and next_func or prev_func
        local _next = reversed and prev_func or next_func
        ensure_last_motion(buf)
        last_motion[buf].prev = make_extra_builtin_func(_prev, args, is_extra_builtin)
        last_motion[buf].next = make_extra_builtin_func(_next, args, is_extra_builtin)
      end
    end
    if reversed then
      return prev_func(...)
    else
      return next_func(...)
    end
  end
end

function M.clear()
  last_motion = {}
  if c.enabled then
    del({ 'n', 'v' }, ',')
    del({ 'n', 'v' }, ';')
  end
  c = nil
end

-- WARN:
-- We do not support 'o' mode now
M.setup = util.setup_check_wrap('lightboat.extra.rep_move', function()
  c = config.get().extra.rep_move
  if not c.enabled then return end
  map({ 'n', 'v' }, ',', function()
    local buf = vim.api.nvim_get_current_buf()
    ensure_last_motion(buf)
    if can_repeat(last_motion[buf].prev) then
      local res = last_motion[buf].prev()
      if type(res) == 'string' then feedkeys(res, 'nt') end
    else
      feedkeys(',', 'nt')
    end
  end, { desc = 'Exteneded comma' })
  map({ 'n', 'v' }, ';', function()
    local buf = vim.api.nvim_get_current_buf()
    ensure_last_motion(buf)
    if can_repeat(last_motion[buf].next) then
      local res = last_motion[buf].next()
      if type(res) == 'string' then feedkeys(res, 'nt') end
    else
      feedkeys(';', 'nt')
    end
  end, { desc = 'Extended semicolon' })
end, M.clear)

--- @param prev_func function|string
--- @param next_func function|string
--- @return function|string, function|string
function M.make(prev_func, next_func)
  c = config.get().extra.rep_move
  if not c.enabled then return prev_func, next_func end
  return repeat_wrap(prev_func, next_func, true), repeat_wrap(prev_func, next_func, false)
end

return M
