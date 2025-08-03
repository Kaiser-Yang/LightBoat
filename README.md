# LightBoat

Faster, faster and faster! A neovim distro based on my dotfiles.

## Installation

For better experience, you can use
[LightBoat.starter](https://github.com/Kaiser-Yang/LightBoat.starter) to install this distro.

Check [LightBoat.starter](https://github.com/Kaiser-Yang/LightBoat.starter) to learn how to
install this distro with the starter.

## Customization

### Key Mappings

There are two types of mappings in `LightBoat`:

1. The builtin key mappings, which are defined in the
   [keymap.lua](lua/lightboat/core/keymap.lua)
   file. These key mappings do not depend on other plugins.
2. The key mappings for plugins, which are defined in the plugins' files.

For the second type of key mappings, it can be divided into two sub-types:

1. Those can be customized by configuring `vim.g.lightboat_opts`.
2. Those can not be customized by configuring `vim.g.lightboat_opts`.

#### Customize Type 1 Key Mappings

Those below are the default configuration for some key mappings of type 1:

```lua
return {
  enabled = true,
  delete_default_commant = true,
  delete_default_diagnostic_under_cursor = true,
  keys = {
    ['<m-x>'] = { key = '<m-x>', mode = { 'n', 'x' }, desc = 'Cut to + reg' },
    ['<m-a>'] = { key = '<m-a>', mode = { 'n', 'x', 'i' }, expr = true, desc = 'Select all' },
    ['<c-u>'] = { key = '<c-u>', mode = 'i', desc = 'Delete to start of line' },
    ['<c-w>'] = { key = '<c-w>', mode = 'i', expr = true, remap = true, desc = 'Delete one word backwards' },
    ['<c-a>'] = { key = '<c-a>', mode = { 'x', 'i', 'c' }, expr = true, desc = 'Move cursor to start of line' },
    ['<c-e>'] = { key = '<c-e>', mode = { 'x', 'i', 'c' }, desc = 'Move cursor to end of line' },
    ['<leader>l'] = { key = '<leader>l', desc = 'Split right' },
    ['<leader>j'] = { key = '<leader>j', desc = 'Split below' },
    ['<leader>h'] = { key = '<leader>h', desc = 'Split right' },
    ['<leader>k'] = { key = '<leader>k', desc = 'Split above' },
    ['='] = { key = '=', desc = 'Equalize windows' },
    ['<c-h>'] = { key = '<c-h>', desc = 'Cursor left' },
    ['<c-j>'] = { key = '<c-j>', desc = 'Cursor down' },
    ['<c-k>'] = { key = '<c-k>', desc = 'Cursor up' },
    ['<c-l>'] = { key = '<c-l>', desc = 'Cursor right' },
    ['<leader>T'] = { key = '<leader>T', desc = 'Move current window to a new tabpage' },
    ['<leader>t2'] = { key = '<leader>t2', desc = 'Set tab with 2 spaces' },
    ['<leader>t4'] = { key = '<leader>t4', desc = 'Set tab with 4 spaces' },
    ['<leader>t8'] = { key = '<leader>t8', desc = 'Set tab with 8 spaces' },
    ['<leader>tt'] = { key = '<leader>tt', desc = 'Toggle expandtab' },
    ['F'] = { key = 'F', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Previous find character' },
    ['T'] = { key = 'T', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Previous till character' },
    ['f'] = { key = 'f', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Next find character' },
    ['t'] = { key = 't', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Next till character' },
    ['b'] = { key = 'b', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Previous word' },
    ['w'] = { key = 'w', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Next word' },
    ['B'] = { key = 'B', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Previous big word' },
    ['W'] = { key = 'W', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Next big word' },
    ['ge'] = { key = 'ge', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Previous end word' },
    ['e'] = { key = 'e', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Next end word' },
    ['gE'] = { key = 'gE', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Previous big end word' },
    ['E'] = { key = 'E', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Next big end word' },
    ['N'] = { key = 'N', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Previous search pattern' },
    ['n'] = { key = 'n', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Next search pattern' },
    ['[s'] = { key = '[s', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Previous misspelled word' },
    [']s'] = { key = ']s', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Next misspelled word' },
    ['[z'] = { key = '[z', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Move to start of current fold' },
    [']z'] = { key = ']z', mode = { 'n', 'o', 'x' }, expr = true, desc = 'Move to end of current fold' },
    ['zk'] = { key = 'zk', mode = { 'n', 'o', 'x' }, expr = true, desc = 'To the end of the previous fold' },
    ['zj'] = { key = 'zj', mode = { 'n', 'o', 'x' }, expr = true, desc = 'To the start of the next fold' },
    ['<c-n>'] = { key = '<c-n>', mode = 'i' },
    ['<c-p>'] = { key = '<c-p>', mode = 'i' },
    ['<leader>sc'] = { key = '<leader>sc', desc = 'Toggle spell check' },
    ['<leader>ts'] = { key = '<leader>ts', desc = 'Toggle treesitter highlight' },
    ['<leader>i'] = { key = '<leader>i', desc = 'Toggle inlay hints' },
  },
}
```

If you want to customize some key mappings. For example, you man want to use `<c-s>` to split
the window, you just need to update the `key` fields of the origin key mappings:

```lua
-- Make sure the variable is not `nil`
vim.g.lightboat_opts = {}
vim.g.lightboat_opts.keymap = {}
vim.g.lightboat_opts.keymap.keys = {
  -- Use '<c-s>' to split vertically
  ['<leader>l'] = { key = '<c-s>' },
  -- Disable the `<leader>h` key mapping
  ['<leader>h'] = false,
}
```

When you customize the key mappings, you should be careful that your new key is not
occupied by `LightBoat`. To do so, you can use `:map <c-s>` to check if the key is occupied.
In this case, you will get output like:

```
s  <C-S>       *@<Lua 1326: ~/.local/share/nvim/lazy/blink.cmp/lua/blink/cmp/keymap/apply.lua:41>
                 blink.cmp
n  <C-S>       * <Lua 358: ~/.local/share/nvim/lazy/lazy.nvim/lua/lazy/core/handler/keys.lua:121>
                 Flash Search Two Characters
x  <C-S>       * <Lua 163: ~/.local/share/nvim/lazy/lazy.nvim/lua/lazy/core/handler/keys.lua:121>
                 Flash Search Two Characters
s  <C-S>       * <Lua 22: vim/_defaults.lua:0>
                 vim.lsp.buf.signature_help()
```

These are telling you that the `<c-s>` in `n`, `x`, and `s` modes are occupied.

#### Customize Type 2-1 Mappings

Let's take a look at the default key mappings or `comment`:

```lua
return {
  enabled = true,
  keys = {
    ['<leader>A'] = { key = '<leader>A', desc = 'Comment insert end of line' },
    ['<leader>O'] = { key = '<leader>O', desc = 'Comment insert above' },
    ['<leader>o'] = { key = '<leader>o', desc = 'Comment insert below' },
    ['<leader>c'] = { key = '<leader>c', desc = 'Comment toggle linewise' },
    ['<leader>C'] = { key = '<leader>C', desc = 'Comment toggle blockwise' },
    ['<m-/>'] = {
      key = '<m-/>',
      mode = { 'n', 'x', 'i' },
      expr = true,
      remap = true,
      desc = 'Toggle comment for current line',
    },
    ['<m-?>'] = {
      key = '<m-?>',
      mode = { 'n', 'x', 'i' },
      expr = true,
      remap = true,
      desc = 'Comment toggle current block',
    },
  },
}
```

To customize these above, you just need to update the `key` fields. For example, you want to update
`<m-/>` into `<c-/>`, you can do this below:

```lua
vim.g.lightboat_opts = {}
vim.g.lightboat_opts.comment = {}
vim.g.lightboat_opts.comment.keys = {
  -- NOTE:
  -- `<c-/>` is a little bit special in nvim.
  -- To know what `<c-/>` really is in your terminal,
  -- you can press `<c-v><c-/>` in insert mode, which will give you the right key to binding
  ['<m-/>'] = { key = '' },
}
```

To know what is the current configuration, you can run
`:lua vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(vim.inspect(vim.g.lightboat_opts), '\n'))`
in an empty buffer, this will set current buffer with the current configuration.
