local M = {}

local blink_cmp_available = require('lightboat.util').plugin_available('blink.cmp')
local function check()
  if not blink_cmp_available then
    vim.notify('blink.cmp is not available', vim.log.levels.WARN, { title = 'Light Boat' })
    return false
  end
  return true
end
function M.next_completion_item()
  if not check() then return false end
  return require('blink.cmp').select_next()
end
function M.previous_completion_item()
  if not check() then return false end
  return require('blink.cmp').select_prev()
end
function M.accept_completion_item()
  if not check() then return false end
  return require('blink.cmp').accept()
end
function M.cancel_completion()
  if not check() then return false end
  return require('blink.cmp').cancel()
end
function M.show_completion()
  if not check() then return false end
  return require('blink.cmp').show()
end
function M.hide_completion()
  if not check() then return false end
  return require('blink.cmp').hide()
end
function M.snippet_forward()
  if not check() then return false end
  return require('blink.cmp').snippet_forward()
end
function M.snippet_backward()
  if not check() then return false end
  return require('blink.cmp').snippet_backward()
end
function M.toggle_signature()
  if not check() then return false end
  return require('blink.cmp').show_signature() or require('blink.cmp').hide_signature()
end
function M.scroll_documentation_up()
  if not check() then return false end
  return require('blink.cmp').scroll_documentation_up()
end
function M.scroll_documentation_down()
  if not check() then return false end
  return require('blink.cmp').scroll_documentation_down()
end
function M.scroll_signature_up()
  if not check() then return false end
  return require('blink.cmp').scroll_signature_up()
end
function M.scroll_signature_down()
  if not check() then return false end
  return require('blink.cmp').scroll_signature_down()
end

return M
