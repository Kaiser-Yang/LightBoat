local util = require('lightboat.util')
local group
local config = require('lightboat.config')
local c
local M = {}

local os_name = vim.fn.has('mac') == 1 and 'mac' or vim.fn.has('win32') == 1 and 'win' or 'linux'
local jdtls_config

local spec = {
  'mfussenegger/nvim-jdtls',
  ft = { 'java' },
  -- NOTE:
  -- java 21 required
  -- python 3.9 required
  enabled = vim.fn.executable('java') == 1,
}

function M.clear()
  if group then
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
  end
  jdtls_config = nil
  c = nil
end

function M.get_jdtls_config()
  if not jdtls_config then
    local jdtls_path = vim.fn.expand('$MASON/packages/jdtls')
    local bundles = vim.split(vim.fn.glob('$MASON/packages/java-debug-adapter/extension/server/*.jar'), '\n')
    vim.list_extend(bundles, vim.split(vim.fn.glob('$MASON/packages/java-test/extension/server/*.jar'), '\n'))
    local ignored_bundles = { 'com.microsoft.java.test.runner-jar-with-dependencies.jar', 'jacocoagent.jar' }
    local function should_ignore_bundle(bundle)
      for _, ignored in ipairs(ignored_bundles) do
        if string.find(bundle, ignored, 1, true) then return true end
      end
    end
    bundles = vim.tbl_filter(function(bundle) return bundle ~= '' and not should_ignore_bundle(bundle) end, bundles)
    jdtls_config = {
      settings = { java = { eclipse = { downloadSources = true }, maven = { downloadSources = true } } },
      init_options = { bundles = bundles },
      cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xmx1g',
        '--add-modules=ALL-SYSTEM',
        '--add-opens',
        'java.base/java.util=ALL-UNNAMED',
        '--add-opens',
        'java.base/java.lang=ALL-UNNAMED',
        '-javaagent:' .. vim.fn.expand('$MASON/packages/lombok-nightly/lombok.jar'),
        '-jar',
        jdtls_path .. '/plugins/org.eclipse.equinox.launcher.jar',
        '-configuration',
        jdtls_path .. '/config_' .. os_name,
        '-data',
        '',
      },
      capabilities = require('blink.cmp').get_lsp_capabilities(),
    }
  end
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
  local workspace_dir = vim.fn.stdpath('data') .. '/jdtls-workspace/' .. project_name
  jdtls_config.cmd[#jdtls_config.cmd] = workspace_dir
  jdtls_config.root_dir = vim.fs.root(vim.fn.getcwd(), c.root_markers or {}) or vim.fs.root(0, c.root_markers or {})
  return jdtls_config
end

function M.spec() return spec end

M.setup = util.setup_check_wrap('lightboat.plugin.code.nvim_jdtls', function()
  c = config.get()
  if not vim.fn.executable('java') then return spec end
  group = vim.api.nvim_create_augroup('LightBoatJdtls', {})
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'java',
    callback = function()
      if require('lightboat.extra.big_file').is_big_file() then
        vim.notify('Skipping jdtls for big file', vim.log.levels.WARN)
      end
      require('jdtls').start_or_attach(M.get_jdtls_config())
    end,
  })
  return spec
end, M.clear)

return M
