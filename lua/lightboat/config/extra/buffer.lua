return {
  enabled = true,
  visible_buffer_limit = 10,
  keys = { Q = { key = 'Q', desc = 'Smart quit' } },
  --- @string 'lru' | 'lfu'
  cache_type = 'lru',
  --- @param buf number
  is_visible_buffer = function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].filetype ~= 'qf'
  end,
}
