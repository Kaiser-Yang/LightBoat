local function try_to_paste_image_wrap(put_after, use_curl)
  return function()
    if vim.tbl_contains({ 'c' }, vim.fn.mode('1')) then return false end
    if vim.tbl_contains({ 'gitcommit' }, vim.bo.filetype) then return false end
    if not vim.tbl_contains(require('lightboat.config').get().extra.markdown_fts, vim.bo.filetype) then return false end
    local ok, img_clip = pcall(require, 'img-clip')
    if not ok then return false end
    local clipboard = require('img-clip.clipboard')
    local res
    if clipboard.content_is_image() then
      res = true
    else
      local util = require('img-clip.util')
      local content = util.sanitize_input(clipboard.get_content())
      if use_curl then
        res = util.is_image_url(content) or util.is_image_path(content)
      else
        -- NOTE:
        -- 'img-clip' now only supports pasting those image types
        local image_exts = { '.png', '.jpg', '.jpeg' }
        for _, ext in ipairs(image_exts) do
          if content:find(ext .. '$') then
            res = true
            break
          end
        end
      end
    end
    if res then
      vim.schedule(function()
        local cur_line = vim.api.nvim_get_current_line()
        if vim.fn.mode('1') == 'i' and (not cur_line or cur_line:match('^%s*$')) then
          vim.cmd('normal! dd')
          put_after = false
        end
        img_clip.paste_image({ verbose = false, insert_template_after_cursor = put_after })
      end)
    end
    return res
  end
end

local function big_file_check_wrap(keys, mode)
  return function()
    if not require('lightboat.extra.big_file').is_big_file() then return false end
    if not keys then
      vim.notify('File is too big, and the operation is aborted', vim.log.levels.WARN)
    else
      require('lightboat.util').key.feedkeys(keys, mode and mode or 'n')
    end
    return true
  end
end

return {
  big_file_check_wrap = big_file_check_wrap,
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
  big_file_check = big_file_check_wrap(),
  check_markdown_fts = function()
    local fts = require('lightboat.config').get().extra.markdown_fts
    return not vim.tbl_contains(fts, vim.bo.filetype)
  end,
  disable_in_gitcommit = function() return vim.bo.filetype == 'gitcommit' end,
  try_to_paste_image_p = try_to_paste_image_wrap(true),
  try_to_paste_image_P = try_to_paste_image_wrap(false),
  try_to_paste_image_p_with_curl = try_to_paste_image_wrap(true, true),
  try_to_paste_image_P_with_curl = try_to_paste_image_wrap(false, true),
}
