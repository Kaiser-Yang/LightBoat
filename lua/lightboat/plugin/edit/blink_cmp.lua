local u = require('lightboat.util')
local c = require('lightboat.condition')
local blink_cmp_dictionary_available = c():plugin_available('blink-cmp-dictionary')
local blink_ripgrep_available = c():plugin_available('blink-ripgrep.nvim')
return {
  'saghen/blink.cmp',
  cond = not vim.g.vscode,
  version = '1.*',
  dependencies = {
    'Kaiser-Yang/blink-cmp-dictionary',
    'rafamadriz/friendly-snippets',
    {
      'mikavilpas/blink-ripgrep.nvim',
      enabled = vim.fn.executable('rg') == 1,
      cond = not vim.g.vscode,
    },
  },
  event = { 'InsertEnter', 'CmdlineEnter' },
  opts = {
    sources = {
      default = function()
        local res = { 'snippets', 'lsp', 'path', 'buffer' }
        if blink_ripgrep_available() then table.insert(res, 'ripgrep') end
        if blink_cmp_dictionary_available() then table.insert(res, 'dictionary') end
        return res
      end,
      providers = {
        buffer = {
          name = 'Buff',
          transform_items = function(context, items)
            -- Do not convert case when searching
            if context.mode == 'cmdline' then return items end
            local out = {}
            for _, item in ipairs(items) do
              --- @type string
              local raw = item.insertText
              table.insert(out, item)
              local item1 = vim.deepcopy(item)
              item1.insertText, item1.label = raw:lower(), raw:lower()
              table.insert(out, item1)
              local item2 = vim.deepcopy(item)
              item2.insertText, item2.label = raw:upper(), raw:upper()
              table.insert(out, item2)
              local item3 = vim.deepcopy(item)
              item3.insertText, item3.label = raw:sub(1, 1):upper() .. raw:sub(2), raw:sub(1, 1):upper() .. raw:sub(2)
              table.insert(out, item3)
              local item4 = vim.deepcopy(item)
              item4.insertText, item4.label = raw:sub(1, 1):lower() .. raw:sub(2), raw:sub(1, 1):lower() .. raw:sub(2)
              table.insert(out, item4)
            end
            return out
          end,
        },
        lsp = { fallbacks = {} },
        path = { opts = { show_hidden_files_by_default = true } },
        snippets = { name = 'Snip' },
        dictionary = {
          name = 'Dict',
          module = 'blink-cmp-dictionary',
          enabled = function() return blink_cmp_dictionary_available() end,
          min_keyword_length = 1,
          opts = { dictionary_files = { u.get_light_boat_root() .. '/dict/en_dict.txt' } },
        },
        ripgrep = {
          name = 'RG',
          module = 'blink-ripgrep',
          enabled = function() return blink_ripgrep_available() and u.git.is_git_repository() end,
          opts = {
            fallback_to_regex_highlighting = true,
            backend = {
              prefix_min_len = 1,
              context_size = 5,
              project_root_fallback = false,
              ripgrep = {
                search_casing = '--smart-case',
                additional_rg_options = { '-m', '100' },
              },
            },
          },
        },
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
}
