local M = {}

local group
local detected

local function clear_autocmds()
    if not group then return end
    vim.api.nvim_del_augroup_by_id(group)
    group = nil
end

function M.clear()
    detected = nil
    clear_autocmds()
end

local function start()
    if detected then
        clear_autocmds()
        return
    end
    vim.system({ 'git', 'rev-parse', '--is-inside-work-tree' }, {
        text = true,
        cwd = vim.fn.getcwd(),
    }, function(out)
        if out.code ~= 0 then return end
        detected = true
        vim.schedule(function()
            vim.api.nvim_exec_autocmds('User', { pattern = 'GitRepoDetected' })
            clear_autocmds()
        end)
    end)
end

--- Detect if the working directory is a Git repository.
--- This function only works once. Once a git repository is detected,
--- it will not check again. When a git repository is detected,
--- it will trigger the `User GitRepoDetected` autocommand.
function M.detect()
    if vim.fn.executable('git') == 0 then return end
    if detected then return end
    -- Detect once for the current directory
    start()
    group = vim.api.nvim_create_augroup('LightBoatGitDetect', {})
    vim.api.nvim_create_autocmd('DirChanged', {
        group = group,
        callback = start,
    })
end

--- Detect if the buffer is in a Git repository.
---@param buffer number?
---@return boolean
function M.is_git_repository(buffer) return vim.fs.root(buffer or 0, '.git') ~= nil end

return M
