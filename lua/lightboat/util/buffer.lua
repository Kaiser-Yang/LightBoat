local M = {}

--- Normalize the buffer number to its real buffer identity.
function M.normalize_buf(buf)
    buf = buf or 0
    if buf == 0 then buf = vim.api.nvim_get_current_buf() end
    return buf
end

--- Check if the buffer is a big file.
--- @param buf number? The buffer number, defaults to the current buffer.
--- @return boolean True if the buffer is a big file, false otherwise.
function M.is_big_file(buf)
    buf = M.normalize_buf(buf)
    local big_file_total = vim.b.big_file_total or vim.g.big_file_total
    local big_file_avg_line = vim.b.big_file_avg_line or vim.g.big_file_avg_line
    local fs_size
    if big_file_total then
        fs_size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
        if fs_size > big_file_total then return true end
    end
    if big_file_avg_line then
        fs_size = fs_size or vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
        local line_count = vim.api.nvim_buf_line_count(buf)
        if fs_size > big_file_avg_line * line_count then return true end
    end
    return false
end

--- Check if a buffer is visible
--- A valid and listed buffer is considered visible.
--- @param buf number? Default to the current buffer.
--- @return boolean True if the buffer is visible, false otherwise.
function M.is_visible_buffer(buf)
    buf = M.normalize_buf(buf)
    return vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_get_option_value('buflisted', { buf = buf })
end

--- Get a list of all visible buffers.
--- A visible buffer is one that is valid and listed.
--- @return number[] A list of visible buffer numbers.
function M.get_visible_bufs()
    local res = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if M.is_visible_buffer(buf) then table.insert(res, buf) end
    end
    return res
end

return M
