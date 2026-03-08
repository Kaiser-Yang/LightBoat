-- TODO:
-- completion for dap commands
local M = {}

local operation = {
  ['<leader>dt'] = function()
    if vim.bo.filetype == 'java' then
      local ok, jdtls = pcall(require, 'jdtls')
      if not ok then
        vim.notify('jdtls not found, please install it first.', vim.log.levels.WARN)
        return
      end
      jdtls.test_nearest_method()
    else
      vim.notify('Not support for current filetype: ' .. vim.bo.filetype, vim.log.levels.WARN)
    end
  end,
}
