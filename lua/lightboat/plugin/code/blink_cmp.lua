local function provider_enabled() return not require('lightboat.extra.big_file').is_big_file() end
return {

  'saghen/blink.cmp',
  cond = not vim.g.vscode,
  dependencies = {
    { 'rafamadriz/friendly-snippets', cond = not vim.g.vscode },
  },
  version = '1.*',
  event = 'VeryLazy',
  opts = {
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      providers = {
        buffer = { enabled = provider_enabled, name = 'Buff' },
        lsp = { enabled = provider_enabled, fallbacks = {} },
        path = { opts = { show_hidden_files_by_default = true } },
        snippets = { name = 'Snip' },
      },
    },
    keymap = { preset = 'none' },
    completion = {
      menu = {
        scrolloff = 0,
        max_height = 15,
        draw = {
          padding = 0,
          align_to = 'cursor',
          columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'source_name' } },
          components = { source_name = { text = function(ctx) return '[' .. ctx.source_name .. ']' end } },
        },
      },
      documentation = { auto_show = true },
    },
    cmdline = {
      keymap = { preset = 'none' },
      completion = { menu = { auto_show = true }, ghost_text = { enabled = false } },
    },
    signature = { enabled = true },
  },
  config = function(_, opts)
    require('blink.cmp').setup(opts)
    local original = require('blink.cmp.completion.list').show
    require('blink.cmp.completion.list').show = function(ctx, items_by_source)
      local seen = {}
      local function filter(item)
        if seen[item.label] then return false end
        seen[item.label] = true
        return true
      end
      -- HACK:
      -- This is a hack, see https://github.com/saghen/blink.cmp/issues/1222#issuecomment-2891921393
      for id in vim.iter({ 'snippets', 'lsp', 'dictionary', 'buffer', 'ripgrep' }) do
        items_by_source[id] = items_by_source[id] and vim.iter(items_by_source[id]):filter(filter):totable()
      end
      return original(ctx, items_by_source)
    end
  end,
}
