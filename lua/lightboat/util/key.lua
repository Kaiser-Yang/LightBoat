local group = vim.api.nvim_create_augroup('LightBoatKeymapUtil', {})
local M = {}

--- Make letters inside angle brackets lowercase, except for
--- '<M-A>' or '<m-A>', which become '<m-A>',
--- which is because <m-a> and <M-a> are equivalent in Neovim,
--- but <m-a> and <m-A> are not.
--- @param s string
--- @return string
local function lower_bracket(s)
  local res, _ = s:gsub('%b<>', function(m)
    local inner = m:sub(2, -2)
    if inner:match('^[mM]%-%a$') then
      inner = 'm' .. inner:sub(2)
    else
      inner = inner:lower()
    end
    return '<' .. inner .. '>'
  end)
  return res
end

--- Normalise keys in a KeySpec, making sure '<C-A>' and '<c-a>' are treated the same.
--- @generic T: LightBoat.GlobalKeySpec | LightBoat.BufferKeySpec
--- @param t T
--- @return T
function M.normalise_key(t)
  local res = {}
  for lhs, key_chain in pairs(t) do
    local new_lhs = lower_bracket(lhs)
    res[new_lhs] = key_chain
    res[new_lhs].key = lower_bracket(key_chain.key)
    if res[new_lhs].handler['fallback'] == nil then
      res[new_lhs].handler['fallback'] = {
        priority = -math.huge,
        handler = function() return key_chain.key end,
      }
    end
  end
  return res
end

--- @param ev LightBoat.EventSpec
--- @return LightBoat.ComplexEventSpec
local function ensure_complex_event(ev)
  if type(ev) == 'string' then
    return { event = ev }
  else
    return ev
  end
end

--- @param key_spec LightBoat.GlobalKeySpec | LightBoat.BufferKeySpec
--- @return vim.keymap.set.Opts
local function generate_opt(key_spec)
  local opt = vim.deepcopy(key_spec)
  opt.key = nil
  opt.mode = nil
  opt.extra_opts = nil
  opt.map_on_event = nil
  opt.unmap_on_event = nil
  opt.handler = nil
  return opt
end

--- Delete a map
--- @param key_spec LightBoat.KeyChainSpec
local function del(key_spec) pcall(vim.keymap.del, key_spec.mode, key_spec.key, { buffer = key_spec.buffer }) end

--- @param key_spec LightBoat.BufferKeyChainSpec
local function del_on_event(key_spec)
  if not key_spec.unmap_on_event then return end
  for _, ev in ipairs(key_spec.unmap_on_event) do
    ev = ensure_complex_event(ev)
    vim.api.nvim_create_autocmd(ev.event, {
      group = group,
      pattern = ev.pattern,
      callback = function() del(key_spec) end,
      once = true,
    })
  end
end

--- @param key_spec LightBoat.KeyChainSpec
--- @return function
local function handler_wrap(key_spec)
  local util = require('lightboat.util')
  --- @type LightBoat.KeyHandlerSpec[]
  local parsed_handler = {}
  for _, handler in pairs(key_spec.handler) do
    if type(handler) ~= 'boolean' then table.insert(parsed_handler, handler) end
  end
  table.sort(parsed_handler, function(a, b) return a.priority > b.priority end)
  return function()
    local ret
    for _, v in ipairs(parsed_handler) do
      ret = util.get(v.handler)
      if ret then
        if type(ret) ~= 'string' then return '' end
        return ret
      end
    end
  end
end

--- Set a keymap
--- @param key_spec LightBoat.KeyChainSpec
local function set(key_spec) vim.keymap.set(key_spec.mode, key_spec.key, handler_wrap(key_spec), generate_opt(key_spec)) end

--- @param key_spec LightBoat.BufferKeyChainSpec
local function set_buffer_key(key_spec)
  for _, ev in ipairs(key_spec.map_on_event) do
    ev = ensure_complex_event(ev)
    vim.api.nvim_create_autocmd(ev.event, {
      group = group,
      pattern = ev.pattern,
      callback = function()
        set(key_spec)
        del_on_event(key_spec)
      end,
    })
  end
end

--- @param buffer_key LightBoat.BufferKeySpec
function M.setup_buffer_key(buffer_key)
  for _, key_spec in pairs(buffer_key) do
    if type(key_spec) ~= 'boolean' then set_buffer_key(key_spec) end
  end
end

--- @param global_key LightBoat.GlobalKeySpec
function M.setup_global_key(global_key)
  for _, key_spec in pairs(global_key) do
    if type(key_spec) ~= 'boolean' then set(key_spec) end
  end
end

--- @type string?
local last_key = nil
local on_key_ns_id = vim.on_key(function(key, typed) last_key = typed or key end, nil)
function M.last_key() return last_key end

--- @param keys string
--- @param mode string
function M.feedkeys(keys, mode)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, true, true)
  vim.api.nvim_feedkeys(termcodes, mode, false)
end

--- @param keys string
--- @return string
function M.termcodes(keys) return vim.api.nvim_replace_termcodes(keys, true, true, true) end

--- @param lazy boolean?
--- @return vim.keymap.set.Opts
function M.convert(opts, lazy)
  local res = vim.deepcopy(opts)
  if not lazy then
    res.mode = nil
  else
    res[1] = res.key
  end
  res.prev = nil
  res.key = nil
  res.opts = nil
  return res
end

function M.prev_operation_wrap(prev, cur)
  local util = require('lightboat.util')
  prev = util.ensure_list(prev)
  if #prev == 0 then return cur end
  return function(...)
    local ret
    prev = util.ensure_list(prev)
    for _, v in ipairs(prev) do
      if action[v] then
        ret = util.get(action[v], ...)
      else
        ret = util.get(v, ...)
      end
      if ret then return ret end
    end
    return util.get(cur, ...)
  end
end

function M.get_lazy_keys(operation, keys)
  if not keys or not operation then return {} end
  local res = {}
  for k, v in pairs(keys) do
    if not v or not operation[k] then goto continue end
    local key = M.convert(v, true)
    key[2] = M.prev_operation_wrap(v.prev, operation[k])
    table.insert(res, key)
    ::continue::
  end
  return res
end

function M.set_keys(operation, keys)
  local util = require('lightboat.util')
  if not keys or not operation then return end
  for k, v in pairs(keys) do
    if not v or not operation[k] then goto continue end
    for _, key in pairs(util.ensure_list(v.key)) do
      M.set(v.mode, key, M.prev_operation_wrap(v.prev, operation[k]), M.convert(v))
    end
    ::continue::
  end
end

function M.clear_keys(operation, keys)
  local util = require('lightboat.util')
  if not keys or not operation then return end
  for k, v in pairs(keys) do
    if not v or not operation[k] then goto continue end
    for _, key in pairs(util.ensure_list(v.key)) do
      M.del(v.mode or 'n', key, { buffer = v.buffer })
    end
    ::continue::
  end
end

return M
