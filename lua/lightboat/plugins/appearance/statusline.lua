--- @param ft_list string|string[]
local function disable_in_ft_wrap(ft_list)
    ft_list = type(ft_list) == 'string' and { ft_list } or ft_list
    return function(str)
        assert(type(ft_list) == 'table', 'Expected a table, got: ' .. type(ft_list))
        for _, f in ipairs(ft_list) do
            if vim.bo.filetype:match(f) then return '' end
        end
        return str
    end
end
local buffer = require('lightboat.util').buffer
local sections = {
    lualine_a = { 'progress', 'location' },
    lualine_b = {
        {
            'branch',
            fmt = disable_in_ft_wrap('dap'),
        },
        {
            'diff',
            fmt = disable_in_ft_wrap('dap'),
        },
        {
            function()
                -- PERF: performance issue for large files
                if buffer.is_big_file() then return '' end
                local last_search = vim.fn.getreg('/')
                if not last_search or last_search == '' then return '' end
                local searchcount = vim.fn.searchcount({ maxcount = 9999 })
                return last_search .. '[' .. searchcount.current .. '/' .. searchcount.total .. ']'
            end,
        },
    },
    lualine_c = {},
    lualine_x = {
        function() return vim.g.rime_enabled and 'ㄓ' or '' end,
        'copilot',
        {
            'encoding',
            fmt = disable_in_ft_wrap('dap'),
        },
        {
            'fileformat',
            fmt = disable_in_ft_wrap('dap'),
        },
        {
            'filetype',
            fmt = disable_in_ft_wrap('dap'),
        },
    },
    lualine_y = { 'quickfix' },
    lualine_z = { 'filename' },
}

return {
    'nvim-lualine/lualine.nvim',
    dependencies = {
        'nvim-tree/nvim-web-devicons',
        'AndreM222/copilot-lualine',
    },
    lazy = false,
    opts = {
        options = {
            icons_enabled = true,
            theme = 'catppuccin',
            component_separators = { left = '', right = '' },
            section_separators = { left = '', right = '' },
            disabled_filetypes = {
                'neo-tree',
                'Avante',
                'AvanteInput',
                'help',
            },
            globalstatus = false,
        },
        sections = sections,
        inactive_sections = sections,
        winbar = {
            lualine_a = {},
            lualine_b = { 'filename' },
            lualine_c = { 'navic' },
            lualine_x = {},
            lualine_y = {},
            lualine_z = {},
        },
        inactive_winbar = {
            lualine_a = {},
            lualine_b = { 'filename' },
            lualine_c = { 'navic' },
            lualine_x = {},
            lualine_y = {},
            lualine_z = {},
        },
        tabline = {},
        extensions = {},
    },
}
