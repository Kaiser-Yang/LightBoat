local M = {}

--- @param name 'options' | 'keymaps' | 'autocmds'
local function load(name)
    local function _load(mod)
        if require('lazy.core.cache').find(mod)[1] then require(mod) end
    end
    _load('lightboat.core.' .. name)
    _load('core.' .. name)
end

function M.setup()
    vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        callback = function()
            load('autocmds')
            load('keymaps')
        end,
    })
end

function M.init() load('options') end

return M
