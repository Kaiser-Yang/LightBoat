return {
  disable_snacks_animate_scroll_once = function()
    if not Snacks or vim.g.snacks_animate_scroll == false then return end
    local origin = vim.g.snacks_animate_scroll
    local buf = vim.api.nvim_get_current_buf()
    vim.g.snacks_animate_scroll = false
    vim.defer_fn(function()
      vim.g.snacks_animate_scroll = origin
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buf then Snacks.scroll.check(win) end
      end
    end, 20)
  end,
  big_file_check = function()
    if require('lightboat.extra.big_file').is_big_file() then
      vim.notify('File is too big, and the operation is aborted', vim.log.levels.WARN)
      return true
    end
  end,
}
