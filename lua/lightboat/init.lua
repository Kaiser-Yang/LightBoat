local M = {}
local util = require('lightboat.util')
local config = require('lightboat.config')
local log = util.log
local group
local debug

function M.clear()
  util.clear_color_detection()
  util.git.clear()
  util.network.clear()
  require('lightboat.extra').clear()
  if debug then
    log.set_level(log.level.INFO)
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  debug = nil
  config.clear()
end

M.setup = util.setup_check_wrap('lightboat', function()
  config.setup()
  debug = config.get().debug
  if debug then
    log.set_level(log.level.DEBUG)
    group = vim.api.nvim_create_augroup('LightBoatDebug', {})
    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'LazyLoad',
      callback = function(ev) log.debug('LazyLoad: ' .. vim.inspect(ev)) end,
    })
  end
  log.debug('Opt: ' .. vim.inspect(config.get()))
  require('lightboat.extra').setup()
  util.network.check()
  util.git.detect()
  util.start_to_detect_color()
end, M.clear)

return M
