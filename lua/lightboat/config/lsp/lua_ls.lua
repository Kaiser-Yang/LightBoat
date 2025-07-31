local util = require('lightboat.util')
return {
  on_init = function(client)
    if not util.in_config_dir() then return end
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
          util.get_light_boat_root(),
        },
      },
    }
  end,
  settings = {
    Lua = {},
  },
}
