local M = {}
local util = require('lightboat.util')
local config = require('lightboat.config')
local c
local log = util.log

function M.ensure_packages(packages)
  packages = util.ensure_list(packages)
  for _, package_name in ipairs(packages) do
    for source in require('mason-registry.sources').iter({ include_uninstalled = true }) do
      local pkg = source:get_package(package_name)
      if pkg and not pkg:is_installed() then pkg:install() end
    end
  end
  log.debug('Mason packages installed: ' .. vim.inspect(packages))
end

local spec = {
  'williamboman/mason.nvim',
  branch = 'v1.x',
  lazy = false,
  config = function(_, opts)
    require('mason').setup(opts)
    M.ensure_packages(c.ensure_installed)
    if not c.mason_bin_first then
      local mason_bin = vim.fn.expand('$MASON/bin')
      local paths = vim.split(vim.env.PATH, ':')
      paths = vim.tbl_filter(function(path) return path ~= mason_bin end, paths)
      table.insert(paths, mason_bin)
      vim.env.PATH = table.concat(paths, ':')
      log.debug('Updated PATH to: ' .. vim.env.PATH)
    end
    log.debug('Mason loaded')
  end,
}

function M.spec() return spec end

function M.clear() c = nil end

M.setup = util.setup_check_wrap('lightboat.plugin.code.mason', function()
  c = config.get().mason
  if not c.enabled then return nil end
  return spec
end, M.clear)

return M
