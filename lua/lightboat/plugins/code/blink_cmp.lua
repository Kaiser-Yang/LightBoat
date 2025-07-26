local util = require('lightboat.util')
local network = util.network
-- HACK:
-- Find a better way to check if we are inside some types
--- @param types string[]
local function inside_block(types)
    if vim.api.nvim_get_mode().mode ~= 'i' then return false end
    local node_under_cursor = vim.treesitter.get_node()
    local parser = vim.treesitter.get_parser(nil, nil, { error = false })
    if not parser or not node_under_cursor then return false end
    local query = vim.treesitter.query.get(parser:lang(), 'highlights')
    if not query then return false end
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1
    for id, node, _ in query:iter_captures(node_under_cursor, 0, row, row + 1) do
        for _, t in ipairs(types) do
            if query.captures[id]:find(t) then
                local start_row, start_col, end_row, end_col = node:range()
                if start_row <= row and row <= end_row then
                    if start_row == row and end_row == row then
                        if start_col <= col and col <= end_col then return true end
                    elseif start_row == row then
                        if start_col <= col then return true end
                    elseif end_row == row then
                        if col <= end_col then return true end
                    else
                        return true
                    end
                end
            end
        end
    end
    return false
end
return {
    { 'Kaiser-Yang/blink-cmp-git', keys = {} },
    { 'Kaiser-Yang/blink-cmp-avante', keys = {} },
    { 'Kaiser-Yang/blink-cmp-dictionary', keys = {} },
    { 'rafamadriz/friendly-snippets', keys = {} },
    { 'mikavilpas/blink-ripgrep.nvim', keys = {} },
    {
        'saghen/blink.cmp',
        version = '*',
        event = { 'InsertEnter', 'CmdlineEnter' },
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            fuzzy = { use_frecency = false },
            completion = {
                accept = { auto_brackets = { enabled = true } },
                keyword = { range = 'prefix' },
                list = { selection = { preselect = false, auto_insert = true } },
                trigger = { show_on_insert_on_trigger_character = false },
                menu = {
                    border = 'rounded',
                    max_height = 15,
                    scrolloff = 0,
                    draw = {
                        align_to = 'label',
                        padding = 0,
                        columns = {
                            { 'kind_icon' },
                            { 'label', 'label_description', gap = 1 },
                            { 'source_name' },
                        },
                        components = {
                            source_name = {
                                text = function(ctx) return '[' .. ctx.source_name .. ']' end,
                            },
                        },
                    },
                },
                documentation = { auto_show = true, window = { border = 'rounded' } },
            },
            signature = {
                enabled = true,
                window = { border = 'rounded', show_documentation = false },
            },
            keymap = {
                preset = 'none',
                -- TODO:
                -- We add this mapping, because blink may disappear when input some non-alphenumeric
                -- We should remove this mapping when blink can handle this case
                ['<c-x>'] = {
                    function(cmp) cmp.show({ providers = { 'snippets' } }) end,
                },
                ['<c-s>'] = { 'show_signature', 'hide_signature', 'fallback' },
                ['<cr>'] = {
                    function(cmp)
                        if not cmp.is_visible() then return false end
                        local completion_list = require('blink.cmp.completion.list')
                        if completion_list.get_selected_item() then return cmp.accept() end
                        local snippet_kind = require('blink.cmp.types').CompletionItemKind.Snippet
                        local input_str = completion_list.context.line:sub(
                            completion_list.context.bounds.start_col,
                            completion_list.context.bounds.start_col
                                + completion_list.context.bounds.length
                        )
                        if
                            #completion_list.items >= 1
                            and completion_list.items[1].kind == snippet_kind
                            and completion_list.items[1].label:sub(1, #input_str) == input_str
                        then
                            return cmp.accept({ index = 1 })
                        end
                        return false
                    end,
                    'fallback',
                },
                ['<tab>'] = { 'snippet_forward', 'fallback' },
                ['<s-tab>'] = { 'snippet_backward', 'fallback' },
                ['<c-u>'] = { 'scroll_documentation_up', 'fallback' },
                ['<c-d>'] = { 'scroll_documentation_down', 'fallback' },
                ['<c-j>'] = { 'select_next', 'fallback' },
                ['<c-k>'] = { 'select_prev', 'fallback' },
                ['<c-c>'] = { 'cancel', 'fallback' },
            },
            cmdline = {
                keymap = {
                    preset = 'none',
                    ['<cr>'] = { 'accept', 'fallback' },
                    ['<c-j>'] = { 'select_next', 'fallback' },
                    ['<c-k>'] = { 'select_prev', 'fallback' },
                },
                completion = {
                    menu = { auto_show = true },
                    ghost_text = { enabled = false },
                    list = { selection = { preselect = false, auto_insert = true } },
                },
            },
            sources = {
                default = function()
                    -- HACK:
                    -- path source works not good enough
                    local res = { 'lsp', 'path' }
                    if not vim.bo.filetype:match('dap') then table.insert(res, 'snippets') end
                    if vim.bo.filetype == 'AvanteInput' then
                        table.insert(res, 'avante')
                    elseif
                        vim.tbl_contains({ 'gitcommit', 'octo' }, vim.bo.filetype)
                        and network.status()
                    then
                        table.insert(res, 'git')
                    end
                    if
                        vim.tbl_contains({ 'markdown', 'text', 'octo', 'Avante' }, vim.bo.filetype)
                        or inside_block({ 'comment', 'string' })
                    then
                        vim.list_extend(res, {
                            'buffer',
                            'ripgrep',
                            'dictionary',
                        })
                    end
                    return res
                end,
                providers = {
                    avante = {
                        name = 'Avante',
                        module = 'blink-cmp-avante',
                    },
                    git = {
                        name = 'Git',
                        module = 'blink-cmp-git',
                    },
                    dictionary = {
                        name = 'Dict',
                        module = 'blink-cmp-dictionary',
                        min_keyword_length = 3,
                        --- @module 'blink-cmp-dictionary'
                        --- @type blink-cmp-dictionary.Options
                        opts = {
                            dictionary_files = {
                                util.get_light_boat_root() .. '/dict/en_dict.txt',
                            },
                        },
                    },
                    lsp = {
                        fallbacks = {},
                        --- @param context blink.cmp.Context
                        --- @param items blink.cmp.CompletionItem[]
                        transform_items = function(context, items)
                            local TYPE_ALIAS = require('blink.cmp.types').CompletionItemKind
                            return vim.tbl_filter(function(item)
                                -- Remove snippets, texts and some keywords from completion list
                                return item.kind ~= TYPE_ALIAS.Snippet
                                    and item.kind ~= TYPE_ALIAS.Text
                                    and not (
                                        item.kind == TYPE_ALIAS.Keyword
                                        and vim.g.filetype_ignored_keyword
                                        and vim.g.filetype_ignored_keyword[vim.bo.filetype]
                                        and vim.tbl_contains(
                                            vim.g.filetype_ignored_keyword[vim.bo.filetype],
                                            item.label
                                        )
                                    )
                            end, items)
                        end,
                    },
                    snippets = { name = 'Snip' },
                    path = {
                        opts = {
                            trailing_slash = false,
                            show_hidden_files_by_default = true,
                        },
                    },
                    ripgrep = {
                        name = 'RG',
                        module = 'blink-ripgrep',
                        ---@module 'blink-ripgrep'
                        ---@type blink-ripgrep.Options
                        opts = {
                            prefix_min_len = 3,
                            context_size = 5,
                            max_filesize = '1M',
                            project_root_marker = vim.g.root_markers,
                            search_casing = '--smart-case',
                            project_root_fallback = false,
                            fallback_to_regex_highlighting = true,
                        },
                        transform_items = function(_, items)
                            if #items > 100 then
                                -- Limit the number of items to 100
                                items = vim.list_slice(items, 1, 100)
                            end
                            return items
                        end,
                    },
                },
            },
        },
        opts_extend = { 'sources.default' },
    },
}
