local M = {}

--- Check if the cursor is within a match of the last search pattern.
--- @return boolean true if the cursor is in a match, false otherwise
function M.cursor_in_match()
    if require('lightboat.extra.big_file').is_big_file() then return false end
    local pattern = vim.fn.getreg('/') -- Get last search pattern
    if pattern == '' then return false end -- Skip if no pattern
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local buf = vim.api.nvim_get_current_buf()
    local matches = vim.fn.matchbufline(buf, pattern, row, row)
    for _, match in pairs(matches) do
        if match.byteidx <= col and match.byteidx + #match.text > col then return true end
    end
    return false
end

return M
