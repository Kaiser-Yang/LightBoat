-- Options extended by LightBoat
vim.g.big_file_limit = 5 * 1024 * 1024 -- 5 MB
vim.g.big_file_limit_per_line = 1 * 1024 -- 1 KB
vim.g.visible_buffer_limit = 10
vim.g.use_mason_bin_first = false
vim.g.root_markers = { '.vscode', '.nvim', '.git' }
vim.g.mason_ensure_installed = {
    -- LSP
    'bash-language-server',
    'clangd',
    'shellcheck',
    'jdtls',
    'lua-language-server',
    'markdown-oxide',
    'eslint-lsp',
    'json-lsp',
    'lemminx',
    'neocmakelsp',
    'tailwindcss-language-server',
    'typescript-language-server',
    'vue-language-server',
    'yaml-language-server',
    'pyright',
    'bazelrc-lsp',

    -- Formatters
    'clang-format',
    'google-java-format',
    'stylua',
    'prettier',
    'buildifier',
    'autopep8',

    -- Tools for debugging and testing
    'java-debug-adapter',
    'java-test',
    'codelldb',
}
vim.g.lsp_hijack_names = {
    'bashls',
    'clangd',
    'eslint',
    'jsonls',
    'lemminx',
    'lua_ls',
    'neocmake',
    'pyright',
    'tailwindcss',
    'ts_ls',
    'vue_ls',
    'yamlls',
    'markdown_oxide',
}

-- System options for Neovim
vim.g.mapleader = '<space>'
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_matchit = 1

vim.o.cmdheight = 0
vim.o.signcolumn = 'yes'
vim.o.jumpoptions = 'stack'
vim.o.termguicolors = true
vim.o.spelllang = 'en_us,en'
vim.o.timeoutlen = 300
vim.o.ttimeoutlen = 0
vim.o.mouse = 'a'
vim.o.number = true
vim.o.numberwidth = 3
vim.o.scrolloff = 5
vim.o.colorcolumn = '100'
vim.o.cursorline = true
vim.o.list = true
vim.o.listchars = 'tab:»-,trail:·,lead:·'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.hlsearch = true
-- Use spaces to substitute tabs
vim.o.expandtab = true
-- One tab is shown as 4 spaces
vim.o.tabstop = 4
-- >> and << will shift lines by 4
vim.o.shiftwidth = 4
vim.o.foldlevel = 99
vim.o.foldminlines = 5
vim.o.sessionoptions = 'buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions'
vim.o.formatoptions = 'jcrql'

vim.filetype.add({
    pattern = {
        ['.*.bazelrc'] = 'bazelrc',
    },
})

vim.treesitter.language.register('objc', { 'objcpp' })
