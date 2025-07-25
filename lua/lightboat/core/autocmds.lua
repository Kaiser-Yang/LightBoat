local group = vim.api.nvim_create_augroup('LightBoatBuiltin', {})
local util = require('lightboat.util')
local lfu = util.lfu
local search = util.search
local buffer = util.buffer

-- Disable hlsearch when leaving normal mode
vim.api.nvim_create_autocmd('ModeChanged', {
    group = group,
    pattern = 'n:[^n]',
    callback = function()
        vim.schedule(function() vim.cmd('nohlsearch') end)
    end,
})
-- Disable hlsearch, when moving cursor out of a match
vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
    group = group,
    callback = function()
        local mode = vim.fn.mode()
        if mode ~= 'n' then return end -- Only handle normal mode
        if not search.cursor_in_match() then vim.schedule(function() vim.cmd('nohlsearch') end) end
    end,
})
-- Update the colorcolumn when entering a gitcommit buffer
vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'gitcommit',
    callback = function() vim.wo.colorcolumn = '50,72' end,
})
-- Delete all non-modifiable buffers on VimLeavePre
vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if not vim.bo[buf].modifiable then vim.api.nvim_buf_delete(buf, { force = true }) end
        end
    end,
})
-- Automatically start treesitter based on types and sizes of files
vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
        if buffer.is_big_file(args.buf) then return end
        pcall(vim.treesitter.start)
    end,
})
-- When entering a buffer, we update the cache
vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
        if not vim.g.visible_buffer_limit or not buffer.is_visible_buffer() then return end
        _G.buffer_cache = _G.buffer_cache or lfu.new(vim.g.visible_buffer_limit)
        local deleted_buffers = {}
        if _G.buffer_cache.capacity ~= vim.g.visible_buffer_limit then
            local res = _G.buffer_cache:set_capacity(vim.g.visible_buffer_limit)
            for _, key_value in ipairs(res) do
                table.insert(deleted_buffers, key_value.key)
            end
        end
        for _, buf in ipairs(buffer.get_visible_bufs()) do
            if _G.buffer_cache:contains(buf) then goto continue end
            if _G.buffer_cache:full() then
                table.insert(deleted_buffers, buf)
            else
                _G.buffer_cache:set(buf, true)
            end
            ::continue::
        end
        local deleted_buf, _ = _G.buffer_cache:set(vim.api.nvim_get_current_buf(), true)
        if deleted_buf then table.insert(deleted_buffers, deleted_buf) end
        for _, buf in ipairs(deleted_buffers) do
            local res = vim.api.nvim_cmd({
                cmd = 'bdelete',
                args = { buf },
                bang = false, -- do not add a bang to the command
            }, { output = true })
            if not res:match('^%s*$') then
                vim.notify(
                    'Failed to delete buffer '
                        .. buf
                        .. ': '
                        .. res
                        .. 'buffer_cache will be disabled. '
                        .. 'Reset vim.g.visible_buffer_limit can re-enable it.',
                    vim.log.levels.WARN
                )
                vim.g.visible_buffer_limit = nil
                break
            end
        end
    end,
})
-- When deleting a buffer, we remove it from the cache
vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args)
        if not vim.g.visible_buffer_limit or not _G.buffer_cache then return end
        _G.buffer_cache:del(args.buf)
    end,
})

