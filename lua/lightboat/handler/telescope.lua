local u = require('lightboat.util')
local M = {}

local function find_closing_quote(s, q)
  q = q or '"'
  local n = #s
  local i = 2
  while i <= n do
    local c = s:sub(i, i)
    if c == '\\' then
      i = i + 2
    elseif c == q then
      return i
    else
      i = i + 1
    end
  end
  return nil
end

local function get_input(buffer)
  local line = require('telescope.actions.state').get_current_line()
  local picker = require('telescope.actions.state').get_current_picker(buffer)
  if picker.prompt_title:match('Live Grep') and #line > 0 then
    if line:sub(1, 1) == '"' then
      local idx = find_closing_quote(line)
      if idx == nil then return line end
      return line:sub(1, idx - 1)
    else
      return line:match('^%S*')
    end
  end
  return line
end

local function check()
  if not u.plugin_available('telescope.nvim') then
    vim.notify('telescope.nvim is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end

local function check_frecency()
  if not u.plugin_available('telescope-frecency.nvim') then
    vim.notify('telescope-frecency.nvim is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end

local function check_live_grep_args()
  if not u.plugin_available('telescope-live-grep-args.nvim') then
    vim.notify('telescope-live-grep-args.nvim is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end

local last_input = nil
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'TelescopePrompt',
  callback = function() last_input = nil end,
})
local function escape_for_quote(s, q) return s:gsub(q, '\\' .. q) end
local function unescape_quoted_inner(s, q) return s:gsub('\\' .. q, q) end
local function extract_quoted_and_rest(s, q)
  local end_idx = find_closing_quote(s, q)
  if not end_idx then
    local inner_raw = s:sub(2)
    return unescape_quoted_inner(inner_raw, q), ''
  end
  local inner_raw = s:sub(2, end_idx - 1)
  local inner = unescape_quoted_inner(inner_raw, q)
  local rest = s:sub(end_idx + 1) or ''
  return inner, rest
end

-- Main factory: returns a function suitable for which-key / telescope mappings
-- opts:
--   trim: boolean (trim prompt before processing)
--   quote_char: default '"'
--   postfix: optional string appended after a quoted expression
function M.toggle_quotation_wrap(opts)
  local function ends_with(str, suffix)
    if suffix == nil or suffix == '' then return false end
    return str:sub(-#suffix) == suffix
  end
  opts = opts or {}
  local quote_char = opts.quote_char or '"'
  local postfix = opts.postfix or ''

  return function(prompt_bufnr)
    local action_state = require('telescope.actions.state')
    local picker = action_state.get_current_picker(prompt_bufnr)
    if not picker then return end
    local prompt = picker:_get_prompt() or ''
    if opts.trim then prompt = vim.trim(prompt) end
    if postfix ~= '' then
      if prompt:sub(1, 1) == quote_char then
        local inner, rest = extract_quoted_and_rest(prompt, quote_char)
        local escaped = escape_for_quote(inner, quote_char)
        if ends_with(rest, postfix) then
          -- Already has postfix: just re-quote the inner and rest without postfix
          picker:set_prompt(quote_char .. escaped .. quote_char .. rest:sub(1, #rest - #postfix))
        else
          -- No postfix: add it
          picker:set_prompt(quote_char .. escaped .. quote_char .. rest .. postfix)
        end
      else
        -- Quote it if not quoted, and add postfix
        local escaped = escape_for_quote(prompt, quote_char)
        picker:set_prompt(quote_char .. escaped .. quote_char .. postfix)
      end
      return
    end

    -- No postfix: toggle-ish behavior with last_input memory
    if prompt:sub(1, 1) == quote_char then
      -- quoted: extract inner and save outside content as last_input,
      -- then set prompt to the inner (unescaped)
      local inner, rest = extract_quoted_and_rest(prompt, quote_char)
      last_input = rest
      picker:set_prompt(inner)
      return
    else
      -- not quoted: if last_input exists, place current content into last_input's quotes
      if last_input and last_input ~= '' then
        local escaped = escape_for_quote(prompt, quote_char)
        picker:set_prompt(quote_char .. escaped .. quote_char .. last_input)
        return
      else
        -- no last_input: just wrap current prompt
        local escaped = escape_for_quote(prompt, quote_char)
        picker:set_prompt(quote_char .. escaped .. quote_char)
        return
      end
    end
  end
end
function M.smart_select_all(buffer)
  if not check() then return false end
  local picker = require('telescope.actions.state').get_current_picker(buffer)
  local all_selected = #picker:get_multi_selection() == picker.manager:num_results()
  local a = require('telescope.actions')
  if all_selected then
    a.drop_all(buffer)
  else
    a.select_all(buffer)
  end
  return true
end

function M.toggle_frecency(buffer, opts)
  if not check() or not check_frecency() then return false end
  local input = get_input(buffer)
  local picker = require('telescope.actions.state').get_current_picker(buffer)
  local is_frecency = picker.prompt_title:match('Find File Frecency') ~= nil
  opts = opts or {}
  opts.default_text = opts.default_text or input
  require('telescope.actions').close(buffer)
  if is_frecency then
    require('telescope.builtin').find_files(opts)
  else
    return M.find_file_frecency(opts)
  end
  return true
end

function M.find_file_frecency(opts)
  opts = opts or {}
  opts.previewer = opts.previewer or false
  opts.layout_config = opts.layout_config or {}
  opts.layout_config.anchor = opts.layout_config.anchor or 'N'
  opts.layout_config.anchor_padding = opts.layout_config.anchor_padding or 0
  opts = require('telescope.themes').get_dropdown(opts)
  require('telescope').extensions.frecency.frecency(opts)
  return true
end

function M.find_file_frecency_wrap(opts)
  return function() return M.find_file_frecency(opts) end
end

function M.toggle_frecency_wrap(opts)
  return function(buffer) return M.toggle_frecency(buffer, opts) end
end

function M.toggle_live_grep_frecency(buffer, opts)
  if not check() or not check_frecency() or not check_live_grep_args() then return false end
  local input = get_input(buffer)
  local picker = require('telescope.actions.state').get_current_picker(buffer)
  local is_frecency = picker.prompt_title:match('Live Grep Frecency') ~= nil
  opts = opts or {}
  opts.default_text = opts.default_text or input
  require('telescope.actions').close(buffer)
  if is_frecency then
    require('telescope').extensions.live_grep_args.live_grep_args(opts)
  else
    M.live_grep_frecency(opts)
  end
  return true
end

function M.toggle_live_grep_frecency_wrap(opts)
  return function(buffer) return M.toggle_live_grep_frecency(buffer, opts) end
end

function M.live_grep_frecency(opts)
  if not check() or not check_frecency() or not check_live_grep_args() then return false end
  opts = opts or {}
  opts.prompt_title = opts.prompt_title or 'Live Grep Frecency'
  opts.search_dirs = opts.search_dirs or require('frecency').query()
  opts.layout_config = opts.layout_config or {}
  opts.layout_config.height = opts.layout_config.height or 0.4
  opts = require('telescope.themes').get_ivy(opts)
  require('telescope').extensions.live_grep_args.live_grep_args(opts)
  return true
end

function M.live_grep_frecency_wrap(opts)
  return function() return M.live_grep_frecency(opts) end
end

function M.grep_word(opts)
  if not check() then return false end
  require('telescope.builtin').grep_string(opts)
  return true
end

function M.grep_word_wrap(opts)
  return function() return M.grep_word(opts) end
end
local first = true
function M.help_tags()
  if not check() then return false end
  if first then
    vim.cmd('Lazy load all')
    first = false
  end
  vim.cmd('Telescope help_tags')
end
return M
