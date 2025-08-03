vim.g.mapleader = ' '
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_matchit = 1

vim.o.number = true
vim.o.signcolumn = 'yes'
vim.o.jumpoptions = 'stack'
vim.o.termguicolors = true
vim.o.spelllang = 'en_us,en'
vim.o.timeoutlen = 300
vim.o.ttimeoutlen = 0
vim.o.mouse = 'a'
vim.o.scrolloff = 5
vim.o.cmdheight = 0
vim.o.colorcolumn = '100'
vim.o.cursorline = true
vim.o.list = true
vim.o.listchars = 'tab:»-,trail:·,lead:·'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.hlsearch = true
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.foldlevel = 99
vim.o.foldminlines = 5
vim.o.sessionoptions = 'buffers,curdir,folds,help,tabpages,winsize,winpos'
vim.o.formatoptions = 'jcrql'

vim.filetype.add({
  pattern = {
    ['.*.bazelrc'] = 'bazelrc',
  },
})

vim.treesitter.language.register('objc', { 'objcpp' })
