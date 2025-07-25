return {
    search = require('lightboat.util.search'),
    lfu = require('lightboat.util.lfu'),
    buffer = require('lightboat.util.buffer'),
    key = require('lightboat.util.key'),
    network = require('lightboat.util.network'),
}

function M.get_light_boat_root()
    -- HACK:
    -- Better way to do this?
    return (vim.env.LAZY_PATH or vim.fn.stdpath('data') .. '/lazy/lazy.nvim') .. '/LightBoat'
end

--- @return boolean
function M.has_root_directory()
    if vim.g.root_markers == nil then return false end
    return vim.fs.root(0, vim.g.root_markers) ~= nil
end

return M
