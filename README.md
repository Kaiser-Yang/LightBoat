# LightBoat

Faster, faster and faster! A neovim distro based on my dotfiles.

## FAQs

### How to add a new language server?

By default, only `lua_ls` is enabled when `lua-language-server` is executable.
If you want to add a new language server:

- Install it while `mason.nvim`. You just need to use `:Mason` command to open the
  `mason.nvim` window, and then you can search and install the language server you want.
- Use `vim.lsp.enable(name)` to enable your language server. You can put this line
  in `init.lua`.

Moreover, if you want to change the configuration of a language server, you just need to
create a `lua` file with the name of the language server under `~/.config/nvim/lsp/`.

For example, I want to install `gopls`:

- Use `:Mason`, and find `gopls`.
- Create a file called `gopls.lua` under `~/.config/nvim/lsp/`, and then put
  the configuration you want in this file. For example:

```lua
return {
  settings = {
    gopls = {
      analyses = { unusedparams = true, },
      staticcheck = true,
    },
  },
}
```

- Finally, put `vim.lsp.enable('gopls')` in the end of `init.lua`

Don't know names of language servers?
You can check [here](https://github.com/neovim/nvim-lspconfig/tree/master/lsp).

### How to install language servers automatically?

If you switch to another machine, you may want to install all the language servers
you used before automatically. Create a file named `mason.lua` under the `plugin` directory, then put the following code in the end of your `init.lua`:

```lua
return {
  'williamboman/mason.nvim',
  config = function(_, opts)
    require('mason').setup(opts)
    for i, package_name  in ipairs({ 'lua-language-server', 'gopls' }) do
      for source in require('mason-registry.sources').iter({ include_uninstalled = true }) do
        local pkg = source:get_package(package_name)
        if pkg then pkg:install() end
      end
    end
  end,
}
```

### How to format file automatically on save?

You can put the following code in your `init.lua` to enable auto-format on save:

```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    require("conform").format({ bufnr = args.buf })
  end,
})
```

**NOTE**: You should run `:Mason` at least once to make sure all the sources are loaded, then restart `neovim` to make the above code work.

### How to change the configuration of a plugin?

You just need to create a `lua` file under `lua/plugin` with any name except `init.lua`.
For example, if you want to change the configuration of `saghen/blink.cmp`, you can create
a file called `lua/plugin/blink_cmp.lua`, and then you can write your configuration like below:

```lua
return {
  -- This is the plugin name, you should not change it.
  'saghen/blink.cmp',
  opts = {
    -- Your configuration here
    -- For example, to enable auto-pairs after accepting completion
    completion = { accept = { auto_brackets = true, }, },
  }
}
```

### How to disable auto-brackets after accepting completion?

```lua
-- 'saghen/blink.cmp'
opts.completion.accept.auto_brackets = false
```

### How to customize the border of floating windows?

```lua
-- See :help 'winborder' for more details
vim.o.winborder = 'rounded'
```

## Installation

For better experience, you can use
[LightBoat.starter](https://github.com/Kaiser-Yang/LightBoat.starter) to install this distro.

Check [LightBoat.starter](https://github.com/Kaiser-Yang/LightBoat.starter) to learn how to
install this distro with the starter.

## Useful Shortcuts

### Pairs Related

- [N] `ys{motion}{pair}`: Surround with `{pair}`.
- [N] `yss{pair}`: Surround the whole line with `{pair}`.
- [N] `yS{pair}`: Surround till end of line with `{pair}`.
- [N] `ds{pair}`: Delete surrounding `{pair}`.
- [N] `cs{old_pair}{new_pair}`: Change surrounding from `{old_pair}` to `{new_pair}`.
- [V] `S{pair}`: Surround the selected text with `{pair}`.

**NOTE**: There is a special pair called `f` (function call) provided by `nvim-surround`.
With this pair, you can add, delete, and change function call. For example, `ysiwf` will
let you input a function name, and then it will surround the current word with
`function_name(current_word)`. You can use `dsf` to delete the function call,
and `csf{new_function_name}` to change the function name.

**NOTE**: There is a special pair called `q` (quotation mark) provided by `nvim-surround`.
'', "", and \`\` are all valid pairs. With this pair, you can use `dsq`,
and `csq{pair}` to delete, and change surrounding quotation marks.

**NOTE**: For pair surround, all the opening brackets will add a space around the content,
while all the closing brackets will not add a space around the content. For example,
`ysiw(` will result in `( content )`, while `ysiw)` will result in `(content)`.

### Git Related

- [N] `gcu`: Git current undo. Reset current hunk.
- [N] `gcd`: Git current diff. Show the diff of current hunk.
- [N] `gcl`: Git current blame line. Show the git blame of current line.
- [N] `g]`: Go to next unstaged hunk.
- [N] `g[`: Go to previous unstaged hunk.
- [N] `gca`: Git conflict accept ancestor.
- [N] `gcb`: Git conflict accept both.
- [N] `gcc`: Git conflict accept current.
- [N] `gci`: Git conflict accept incoming.
- [N] `gcn`: Git conflict accept none.
- [N] `]x`: Go to next conflict.
- [N] `[x`: Go to previous conflict.

### Buffers and Windows

- [N] `<leader>{num}`: Go to the `{num}`-th buffer. `0` for the 10-th buffer.
- [N] `<leader>h`: Split vertically and leave the cursor in the left window.
- [N] `<leader>j`: Split horizontally and leave the cursor in the bottom window.
- [N] `<leader>k`: Split horizontally and leave the cursor in the top window
- [N] `<leader>l`: Split vertically and leave the cursor in the right window.
- [N] `<leader>T`: Tab split, you can use this to make a window full screen.
- [N] `<c-h>`: Move to the left window.
- [N] `<c-j>`: Move to the bottom window.
- [N] `<c-k>`: Move to the top window.
- [N] `<c-l>`: Move to the right window.
- [N] `=`: Equalize the size of all windows.
- [N] `<left>`: Resize current window to the left.
- [N] `<down>`: Resize current window to the bottom.
- [N] `<up>`: Resize current window to the top.
- [N] `<right>`: Resize current window to the right.
- [N] `H`: Go to the left buffer of current one in buffer line.
- [N] `L`: Go to the right buffer of current one in buffer line.
- [N] `gb`: Buffer picker. Pick a buffer in buffer line to go to.

### Markdown Related

- [I] `<localleader>1`: Insert heading level 1.
- [I] `<localleader>2`: Insert heading level 2.
- [I] `<localleader>3`: Insert heading level 3.
- [I] `<localleader>4`: Insert heading level 4.
- [I] `<localleader>a`: Insert image block.
- [I] `<localleader>b`: Insert bold line block.
- [I] `<localleader>c`: Insert code block.
- [I] `<localleader>d`: Insert delete line block.
- [I] `<localleader>f`: Move to and remove next placeholder.
- [I] `<localleader>i`: Insert italic line block.
- [I] `<localleader>m`: Insert math line block.
- [I] `<localleader>t`: Insert command line block.
- [I] `<localleader>M`: Insert math block.
- [NV] `gx`: Toggle task list item.

### Motion Related

- [N] `%`: When `{count}` is less than 7, it will move to the `{count}`-th
  matching word. Otherwise, it will move to the `{count}` percentage of the file.
- [N] `g%`: Go to previous matching word.
- [N] `]%`: Go to next outer closing word.
- [N] `[%`: Go to previous outer opening word.
- [N] `z%`: Go to next inner of a block.
- [N] `Z%`: Go to previous inner of a block.

### Others

- [N] `<leader>r`: Run current file with the appropriate program.
- [N] `<leader>tt`: Toggle `expandtab`.
- [N] `<leader>t2`: Set tab with 2 spaces.
- [N] `<leader>t4`: Set tab with 4 spaces.
- [N] `<leader>t8`: Set tab with 8 spaces.

## Customization

### Key Mappings

There are two types of mappings in `LightBoat`:

1. The builtin key mappings, which are defined in the
   [keymap.lua](lua/lightboat/config/keymap/init.lua)
   file. These key mappings do not depend on other plugins.
2. The key mappings for plugins, which are defined in the plugins' files.

For the second type of key mappings, it can be divided into two sub-types:

1. Those can be customized by configuring `vim.g.lightboat_opts`.
2. Those can not be customized by configuring `vim.g.lightboat_opts`.

#### Customize Type 1 Key Mappings

Those below are the default configuration for some key mappings of type 1:

```lua
return {
  keys = {
    -- ...
    ['<leader>l'] = { key = '<leader>l', desc = 'Split right' },
    ['<leader>j'] = { key = '<leader>j', desc = 'Split below' },
    ['<leader>h'] = { key = '<leader>h', desc = 'Split right' },
    ['<leader>k'] = { key = '<leader>k', desc = 'Split above' },
    -- ...
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
  -- Use `<c-s>` to split vertically
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

Let's take a look at the default key mappings of `comment`:

```lua
return {
  keys = {
    -- ...
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

To customize these above, you just need to update the `key` fields.
For example, if you want to update `<m-/>` into `<c-/>`, you can do this below:

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
