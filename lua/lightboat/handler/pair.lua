local u = require('lightboat.util')
local M = {}

local last_count = 1
local surround_available = u.plugin_available('nvim-surround')
local function check()
  if not surround_available then
    vim.notify('nvim-surround is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end
local l = {}
function l.surround_normal()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal)'
end
function l.surround_normal_current()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal-cur)'
end
function l.surround_normal_line()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal-line)'
end
function l.surround_normal_current_line()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-normal-cur-line)'
end
function l.surround_insert()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-insert)'
end
function l.surround_insert_line()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-insert-line)'
end
function l.surround_delete()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-delete)'
end
function l.surround_change()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-change)'
end
function l.surround_change_line()
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-change-line)'
end
local function hack(suffix)
  if not check() then return false end
  suffix = suffix or ''
  local op = vim.v.operator
  if op ~= 'g@' then last_count = vim.v.count1 end
  local res
  if op == 'y' then
    res = l['surround_normal' .. suffix]
  elseif op == 'd' then
    res = l['surround_delete' .. suffix]
  elseif op == 'c' then
    res = l['surround_change' .. suffix]
  elseif op == 'g@' and vim.o.operatorfunc:find('nvim%-surround') then
    res = l['surround_normal_current' .. suffix]
  end
  if not res then return false end
  local key = (op == 'g@' and last_count or vim.v.count1) .. res()
  vim.schedule_wrap(u.key.feedkeys)(key, 'n')
  return '<esc>'
end

local function check_autopair()
  if not u.plugin_available('ultimate-autopair.nvim') then
    vim.notify('ultimate-autopair.nvim is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end

--- @param key string
--- @return string|boolean
local function auto_pair(key)
  if not check_autopair() then return false end
  local core = require('ultimate-autopair.core')
  core.get_run(u.key.termcodes(key))
  return core.run_run(u.key.termcodes(key))
end

local function close_pair_wrap(close, pattern)
  return function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local content_after_cursor = vim.api.nvim_get_current_line():sub(col + 1)
    local next_close = content_after_cursor:match(pattern)
    if not next_close then return close end
    vim.api.nvim_win_set_cursor(0, { row, col + #next_close })
    return ''
  end
end
--- nil   --> quotations are not matched
--- false --> pairs are not matched or not in pairs
--- true  --> in pairs
local function in_pair()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local cnt = {
    ['()'] = 0,
    ['[]'] = 0,
    ['{}'] = 0,
  }
  local match = {
    ['"'] = true,
    ["'"] = true,
    ['`'] = true,
  }
  local pair_ok = true
  for i = 1, #line do
    local ch = line:sub(i, i)
    if ch == '(' then
      cnt['()'] = cnt['()'] + 1
    elseif ch == ')' then
      cnt['()'] = cnt['()'] - 1
    elseif ch == '[' then
      cnt['[]'] = cnt['[]'] + 1
    elseif ch == ']' then
      cnt['[]'] = cnt['[]'] - 1
    elseif ch == '{' then
      cnt['{}'] = cnt['{}'] + 1
    elseif ch == '}' then
      cnt['{}'] = cnt['{}'] - 1
    end
    if match[ch] ~= nil and (ch ~= "'" or i == 1 or not line:sub(i - 1, i - 1):match('%a')) then
      match[ch] = not match[ch]
    end
    if cnt['()'] < 0 or cnt['[]'] < 0 or cnt['{}'] < 0 then pair_ok = false end
  end
  local quotation_ok = match['"'] and match["'"] and match['`']
  if not quotation_ok then return nil end
  if not pair_ok then return false end
  local char_before = col ~= 0 and line:sub(col, col)
    or (row > 1 and vim.api.nvim_buf_get_lines(0, row - 2, row - 1, true)[1]:sub(-1) or '')
  local char_after = col ~= #line and line:sub(col + 1, col + 1)
    or (row < vim.api.nvim_buf_line_count(0) and vim.api.nvim_buf_get_lines(0, row, row + 1, true)[1]:sub(1, 1) or '')
  local matched = ''
  local ok = function(a, b)
    if a and b then matched = a .. b end
    return a
      and b
      and (
        (a == '(' and b == ')')
        or (a == '[' and b == ']')
        or (a == '{' and b == '}')
        or (a == '"' and b == '"')
        or (a == "'" and b == "'")
        or (a == '`' and b == '`')
      )
  end
  if ok(char_before, char_after) then return true, matched end
  if char_before:match('%s') and char_after:match('%s') and col ~= 0 and col ~= #line then
    local non_space_before = line:sub(1, col):match('(%S)%s*$')
    local non_space_after = line:sub(col + 1):match('^%s*(%S)')
    return ok(non_space_before, non_space_after), matched
  end
  return false, matched
end
local double_quotation = {}
local triple_quotation = {
  ['`'] = { 'markdown' },
  ['"'] = { 'python' },
  ["'"] = { 'python' },
}
local function quotation_wrap(sym)
  return function()
    if in_pair() == nil then return sym end
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local sym_before = line:sub(1, col):match(sym .. '*$') or ''
    local sym_after = line:sub(col + 1):match('^' .. sym .. '*') or ''
    if #sym_before == 0 then
      if #sym_after == 1 then return '<right>' end
    elseif #sym_before == 1 then
      if #sym_after == 1 then
        if double_quotation[sym] and vim.tbl_contains(double_quotation[sym], vim.bo.filetype) then
          return sym .. sym .. '<left>'
        else
          return '<right>'
        end
      end
    elseif #sym_before == 2 then
      if #sym_after == 0 then
        if triple_quotation[sym] and vim.tbl_contains(triple_quotation[sym], vim.bo.filetype) then
          return sym .. sym .. sym .. sym .. string.rep('<left>', 3)
        end
      end
    end
    return sym .. sym .. '<left>'
  end
end
local hack_auot_pair_for_big = {
  ['('] = '<c-g>u()<left>',
  ['['] = '<c-g>u[]<left>',
  ['{'] = '<c-g>u{}<left>',
  [')'] = close_pair_wrap(')', '[%s%]%}]*%)'),
  [']'] = close_pair_wrap(']', '[%s%}%)]*%]'),
  ['}'] = close_pair_wrap('}', '[%s%]%)]*%}'),
  [' '] = function()
    local ok, s = in_pair()
    if ok and s:sub(1, 1) ~= s:sub(2, 2) then return '<c-g>U  <left>' end
    return ' '
  end,
  ['"'] = quotation_wrap('"'),
  ["'"] = quotation_wrap("'"),
  ['`'] = quotation_wrap('`'),
  [u.key.termcodes('<bs>')] = function()
    if in_pair() then return '<del><bs>' end
    return '<bs>'
  end,
  [u.key.termcodes('<cr>')] = function()
    if in_pair() then
      return '<c-g>u<cr><cr><up>' .. (vim.bo.indentexpr == '' and vim.o.indentexpr == '' and '<tab>' or '<c-f>')
    end
    return '<cr>'
  end,
}

local function check_blink_pairs()
  if not u.plugin_available('blink.pairs') then
    vim.notify('blink.pairs is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end
local key_to_function
--- @param key string
local function blink_pairs(key)
  if not check_blink_pairs() then return false end
  if key_to_function == nil then
    local m = require('blink.pairs.mappings')
    local rule_lib = require('blink.pairs.rule')
    local config = require('blink.pairs.config')
    local rule_definitions = config.mappings.pairs
    local rules_by_key = rule_lib.parse(rule_definitions)
    local all_rules = rule_lib.get_all(rules_by_key)
    key_to_function = {
      ['<bs>'] = m.backspace(all_rules),
      ['<cr>'] = m.enter(all_rules),
      ['<space>'] = m.space(all_rules),
      ['<'] = m.on_key('<', rules_by_key['<']),
      ['>'] = m.on_key('>', rules_by_key['>']),
      ['('] = m.on_key('(', rules_by_key['(']),
      [')'] = m.on_key(')', rules_by_key[')']),
      ['['] = m.on_key('[', rules_by_key['[']),
      [']'] = m.on_key(']', rules_by_key[']']),
      ['{'] = m.on_key('{', rules_by_key['{']),
      ['}'] = m.on_key('}', rules_by_key['}']),
      ['"'] = m.on_key('"', rules_by_key['"']),
      ["'"] = m.on_key("'", rules_by_key["'"]),
      ['`'] = m.on_key('`', rules_by_key['`']),
      ['!'] = m.on_key('!', rules_by_key['!']),
      ['-'] = m.on_key('-', rules_by_key['-']),
      ['_'] = m.on_key('_', rules_by_key['_']),
      ['*'] = m.on_key('*', rules_by_key['*']),
      ['$'] = m.on_key('$', rules_by_key['$']),
    }
  end
  key = key:lower()
  return key_to_function[key] and key_to_function[key]() or false
end
local blink_pairs_key = {
  '!',
  '-',
  '_',
  '*',
  '$',
  '<',
  '(',
  '[',
  '{',
  '>',
  ')',
  ']',
  '}',
  '"',
  "'",
  '`',
  u.key.termcodes('<bs>'),
  u.key.termcodes('<cr>'),
  u.key.termcodes('<space>'),
}
local auto_pairs_key = {
  ')',
  '}',
  ']',
  u.key.termcodes('<cr>'),
  u.key.termcodes('<m-e>'),
  u.key.termcodes('<m-E>'),
  u.key.termcodes('<m-)>'),
}
local tabout_key = {
  u.key.termcodes('<tab>'),
  u.key.termcodes('<s-tab>'),
}
function M.auto_pair_wrap(key)
  return function()
    local termcodes = u.key.termcodes(key)
    if vim.tbl_contains(auto_pairs_key, termcodes) then
      local res = auto_pair(key)
      if not res then return res end
      assert(type(res) == 'string')
      u.key.feedkeys(res, 'n', false)
      return true
    elseif vim.tbl_contains(tabout_key, termcodes) then
      if u.key.termcodes('<tab>') == termcodes then
        return '<plug>(Tabout)'
      else
        return '<plug>(TaboutBack)'
      end
    elseif vim.tbl_contains(blink_pairs_key, termcodes) then
      return blink_pairs(key)
    end
    return false
  end
end
function M.surround_visual()
  if not check() then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-visual)'
end
function M.surround_visual_line()
  if not check() then return false end
  u.ensure_plugin('nvim-surround')
  return '<plug>(nvim-surround-visual-line)'
end
function M.hack_wrap(suffix)
  return function() return hack(suffix) end
end

return M
