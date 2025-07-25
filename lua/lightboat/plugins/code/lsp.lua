local util = require('lightboat.util')
local buffer = util.buffer
--- @param bufnr integer
--- @param config vim.lsp.Config
local function start_config(bufnr, config)
    return vim.lsp.start(config, {
        bufnr = bufnr,
        reuse_client = config.reuse_client,
        _root_markers = config.root_markers,
    })
end
local function get_lsp_capabilities()
    local ok, blink_cmp = pcall(require, 'blink.cmp')
    if not ok then return {} end
    return blink_cmp.get_lsp_capabilities()
end
local group = vim.api.nvim_create_augroup('LightBoatLsp', {})
local autocmd_id
autocmd_id = vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyLoad',
    group = group,
    callback = function(ev)
        if ev.data ~= 'nvim-lspconfig' then return end
        if not vim.g.lsp_hijack_names or #vim.g.lsp_hijack_names == 0 then goto finished end
        local names = vim.g.lsp_hijack_names
        for _, name in ipairs(names) do
            vim.lsp._enabled_configs[name] = {}
        end
        vim.api.nvim_create_autocmd('FileType', {
            group = group,
            callback = function(args)
                local bufnr = args.buf
                -- PERF:
                -- Large files can cause performance issues with LSP.
                -- Therefore we disable LSP for large files.
                if buffer.is_big_file(bufnr) then
                    vim.notify(
                        'LSP is disabled for this file due to its size.',
                        vim.log.levels.WARN
                    )
                    return
                end
                if vim.bo[bufnr].buftype ~= '' then return end
                for name in pairs(vim.lsp._enabled_configs) do
                    local config = vim.lsp.config[name]
                    if
                        config
                        and vim.lsp.is_enabled(name)
                        and (
                            not config.filetypes
                            or vim.tbl_contains(config.filetypes, vim.bo[bufnr].filetype)
                        )
                    then
                        -- Deepcopy config so chagnes done in the client
                        -- do not propagate to the enabled config
                        config = vim.deepcopy(config)
                        config.capabilities = vim.tbl_deep_extend(
                            'force',
                            get_lsp_capabilities(),
                            config.capabilities or {}
                        )
                        if vim.g.root_markers and #vim.g.root_markers ~= 0 then
                            table.insert(config.root_markers, vim.g.root_markers)
                        end
                        if type(config.root_dir) == 'function' then
                            ---@param root_dir string
                            config.root_dir(bufnr, function(root_dir)
                                config.root_dir = root_dir
                                vim.schedule(function() start_config(bufnr, config) end)
                            end)
                        else
                            start_config(bufnr, config)
                        end
                    end
                end
            end,
        })
        ::finished::
        vim.api.nvim_del_autocmd(autocmd_id)
    end,
})
return {
    'neovim/nvim-lspconfig',
    lazy = false,
}
