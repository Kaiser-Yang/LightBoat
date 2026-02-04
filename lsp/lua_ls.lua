return {
  on_init = function(client)
    local util = require('lightboat.util')
    if not util.in_config_dir() then return end
    local lazy_path = util.lazy_path()
    client.config.settings.Lua = {
      runtime = {
        version = 'LuaJIT',
        path = {
          'lua/?.lua',
          'lua/?/init.lua',
        },
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          lazy_path .. '/LightBoat',
          lazy_path .. '/maplayer.nvim',
          lazy_path .. '/repmove.nvim',
        },
      },
    }
  end,
  settings = { Lua = {} },
}
