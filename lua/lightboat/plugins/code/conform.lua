return {
    'stevearc/conform.nvim',
    cmd = { 'ConformInfo' },
    keys = {
        {
            '<leader>f',
            function()
                require('conform').format({ async = true, lsp_format = 'fallback' }, function()
                    if vim.api.nvim_get_mode().mode ~= 'n' then vim.cmd('normal! <esc>') end
                end)
            end,
            mode = { 'n', 'x' },
            desc = 'Format',
        },
    },
    opts = {
        formatters_by_ft = {
            c = { 'clang-format' },
            cpp = { 'clang-format' },
            python = { 'autopep8' },
            java = { 'google-java-format' },
            markdown = { 'prettier' },
            lua = { 'stylua' },
            vue = { 'prettier' },
            typescript = { 'prettier' },
            javascript = { 'prettier' },
            css = { 'prettier' },
            bzl = { 'buildifier' },
            bazelrc = { 'buildifier' },
        },
    },
}
