local M = {}

local status_cache

function M.status() return status_cache and status_cache end

function M.set(status) status_cache = status end

function M.check(force)
    if not force and status_cache ~= nil then return end
    if force then status_cache = nil end
    local sock = vim.uv.new_tcp()
    if not sock then return end
    local domain = '114.114.114.114'
    sock:connect(domain, 53, function(err)
        if sock then sock:close() end
        M.set(err == nil)
        if err then return end
        vim.schedule(
            function() vim.api.nvim_exec_autocmds('User', { pattern = 'NetworkCheckedOK' }) end
        )
    end)
end

return M
