local M = {}

local status_cache

function M.status() return status_cache end

function M.set(status) status_cache = status end

function M.clear() status_cache = nil end

function M.check()
    if status_cache ~= nil then return end
    local sock = vim.uv.new_tcp()
    if not sock then return end
    local domain = '114.114.114.114'
    sock:connect(domain, 53, function(err)
        if sock then sock:close() end
        M.set(err == nil)
        if err then return end
        vim.schedule(
            function() vim.api.nvim_exec_autocmds('User', { pattern = 'NetworkChecked' }) end
        )
    end)
end

return M
