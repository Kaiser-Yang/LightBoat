-- This idea comes from:
-- https://github.com/mluders/comfy-line-numbers.nvim
-- But I did a lot improvements and changes

--- @class LineWise.Opts
--- @field consider_wrap boolean|fun():boolean Whether or not to act like 'gj' or 'gk' when there is no count
--- @field increase_count boolean Whether or not to increase count by one when there is a count
--- @field consider_invisible boolean Whether or not to consider invisible counts

local util = require('lightboat.util')
local config = require('lightboat.config')
local group
local c

local labels = {}
local function generate_labels()
  local function generate_recursive(current, length)
    if length == 0 then
      table.insert(labels, current)
      labels[current] = #labels
      return
    end
    for i = 1, #c.desired_digits do
      generate_recursive(current .. c.desired_digits:sub(i, i), length - 1)
    end
  end
  for i = 1, c.max_len do
    generate_recursive('', i)
  end
end

function _G.get_label(args)
  local virtnum = args and args.virtnum or vim.v.virtnum
  local relnum = args and args.relnum or vim.v.relnum
  local lnum = args and args.lnum or vim.v.lnum

  if virtnum ~= 0 then return c.format('') end

  if c.enabled then
    local mode = vim.fn.mode('1')
    local line_mode = mode == 'i' and util.get(c.insert)
      or mode == 'c' and util.get(c.command_line)
      or util.get(c.other)
    local function get_insert_label()
      if line_mode == 'abs' then
        return c.format(tostring(lnum))
      elseif line_mode == 'rel' then
        return c.format(tostring(relnum))
      elseif line_mode == 'abs_rel' then
        return c.format(tostring(relnum == 0 and lnum or relnum))
      else
        if relnum == 0 then
          return line_mode == 'line_wise' and '0' or tostring(lnum)
        elseif relnum > 0 and relnum <= #labels then
          return c.format(tostring(labels[relnum]))
        else
          return c.format(tostring(relnum))
        end
      end
    end
    return c.format(get_insert_label())
  else
    local relativenumber = vim.wo.relativenumber
    if relativenumber == nil then relativenumber = vim.o.relativenumber end
    if relativenumber == nil then relativenumber = true end
    if relnum == 0 or not relativenumber then
      return c.format(tostring(lnum))
    else
      return c.format(tostring(relnum))
    end
  end
end

local M = {}

--- @param go_up boolean
--- @param consider_invisible boolean
--- @return number
local function get_actual_count(go_up, consider_invisible)
  local mode = vim.fn.mode('1')
  local line_mode = mode == 'i' and util.get(c.insert) or mode == 'c' and util.get(c.command_line) or util.get(c.other)
  local v_count = vim.v.count
  if line_mode ~= 'line_wise' and line_mode ~= 'abs_line_wise' then return v_count end
  if consider_invisible then return labels[tostring(vim.v.count)] or vim.v.count end
  local treesitter_context_visible_lines = {}
  local cur_win = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative == 'win' and cfg.row == 0 and cfg.win == cur_win and vim.w[win].treesitter_context_line_number then
      local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
      vim.iter(lines):each(function(line)
        -- extract the number from the line
        local number = line:match('^[^%d]*(%d+)[^%d]*$')
        if not number then return end
        treesitter_context_visible_lines[tonumber(number)] = true
      end)
    end
  end
  local actual_count = labels[tostring(v_count)] or v_count
  local target_line = vim.fn.line('.') + (go_up and -actual_count or actual_count)
  local first_visible_line = vim.fn.line('w0')
  local last_visible_line = vim.fn.line('w$')
  if
    (target_line < first_visible_line or target_line > last_visible_line)
    and not treesitter_context_visible_lines[v_count]
  then
    actual_count = v_count
  end
  return actual_count
end

--- @param opts? LineWise.Opts
function M.line_wise_key_wrap(key, opts)
  opts =
    vim.tbl_extend('force', { consider_wrap = false, consider_invisible = true, increase_count = true }, opts or {})
  return function()
    if not c.enabled then return key end
    local actual_count = get_actual_count(key == 'k', opts.consider_invisible)
    local prefix = ''
    if actual_count == 0 then
      if (key == 'j' or key == 'k') and util.get(opts.consider_wrap) then prefix = 'g' end
      return prefix .. key
    else
      if opts.increase_count then actual_count = actual_count + 1 end
      prefix = prefix .. tostring(actual_count)
      return string.rep('<del>', #tostring(vim.v.count)) .. tostring(actual_count) .. key
    end
  end
end

local operation = {
  C = function() return M.line_wise_key_wrap('C', c.keys.C.opts)() end,
  D = function() return M.line_wise_key_wrap('D', c.keys.D.opts)() end,
  dd = function() return M.line_wise_key_wrap('dd', c.keys.dd.opts)() end,
  cc = function() return M.line_wise_key_wrap('cc', c.keys.cc.opts)() end,
  J = function() return M.line_wise_key_wrap('J', c.keys.J.opts)() end,
  j = function() return M.line_wise_key_wrap('j', c.keys.j.opts)() end,
  k = function() return M.line_wise_key_wrap('k', c.keys.k.opts)() end,
  ['<<'] = function() return M.line_wise_key_wrap('<<', c.keys['<<'].opts)() end,
  ['>>'] = function() return M.line_wise_key_wrap('>>', c.keys['>>'].opts)() end,
  ['-'] = function() return M.line_wise_key_wrap('-', c.keys['-'].opts)() end,
  ['+'] = function() return M.line_wise_key_wrap('+', c.keys['+'].opts)() end,
}

function M.clear()
  util.key.clear_keys(operation, c.keys)
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  c = nil
  labels = {}
end

M.setup = util.setup_check_wrap('lightboat.extra.line_wise', function()
  c = config.get().extra.line_wise
  if not c.enabled then return end
  group = vim.api.nvim_create_augroup('LightBoatLineWise', {})
  vim.api.nvim_create_autocmd('ModeChanged', {
    group = group,
    pattern = 'i:n',
    callback = function()
      local _, col = unpack(vim.api.nvim_win_get_cursor(0))
      -- When the cursor is at the beginning,
      -- nvim will not trigger the redraw for line numbers.
      -- Therefore, we trigger this by auto command
      if col == 0 then vim.cmd('redraw') end
    end,
  })
  generate_labels()
  util.key.set_keys(operation, c.keys)
end, M.clear)

return M
