local path_before_mason = vim.env.PATH
local group = vim.api.nvim_create_augroup('LightBoatMason', {})
local autocmd_id
autocmd_id = vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyLoad',
    callback = function(ev)
        if ev.data ~= 'mason.nvim' then return end
        local sources = require('mason-registry.sources')
        for source in sources.iter({ include_uninstalled = true }) do
            for _, package_name in ipairs(vim.g.mason_ensure_installed) do
                local pkg = source:get_package(package_name)
                if pkg and not pkg:is_installed() then pkg:install() end
            end
        end
        if not vim.g.use_mason_bin_first then
            vim.env.PATH = path_before_mason .. ':' .. vim.fn.expand('$MASON/bin')
        end
        vim.api.nvim_del_autocmd(autocmd_id)
    end,
})
return {
    'williamboman/mason.nvim',
    branch = 'v1.x',
    lazy = false,
}
