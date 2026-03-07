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

return {
  try_to_paste_image_p = try_to_paste_image_wrap(true),
  try_to_paste_image_P = try_to_paste_image_wrap(false),
  try_to_paste_image_p_with_curl = try_to_paste_image_wrap(true, true),
  try_to_paste_image_P_with_curl = try_to_paste_image_wrap(false, true),
}
