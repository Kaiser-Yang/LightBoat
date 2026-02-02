local M = {}
local util = require('lightboat.util')

--- @param n integer
--- @return string
function M.markdown_title(n) return '<c-g>u<bs>' .. string.rep('#', n) .. ' ' end

M.markdown_separate_line = '<c-g>u<bs>---<cr><cr>'
M.markdown_math_inline = '<c-g>u<bs>$  $<++>' .. string.rep('<c-g>U<left>', 6)
M.markdown_math_inline_2 = '<c-g>u<bs>$$  $$<++>' .. string.rep('<c-g>U<left>', 7)
M.markdown_code_line = '<c-g>u<bs>``<++>' .. string.rep('<c-g>U<left>', 5)
M.markdown_todo = '<c-g>u<bs>- [ ] '
M.markdown_link = '<c-g>u<bs>[](<++>)<++>' .. string.rep('<c-g>U<left>', 11)
M.markdown_bold = '<c-g>u<bs>****<++>' .. string.rep('<c-g>U<left>', 6)
M.markdown_delete_line = '<c-g>u<bs>~~~~<++>' .. string.rep('<c-g>U<left>', 6)
M.markdown_italic = '<c-g>u<bs>**<++>' .. string.rep('<c-g>U<left>', 5)
M.markdown_math_block = '<c-g>u<bs>$$<cr><cr>$$<cr><cr><++>' .. string.rep('<up>', 3) .. string.rep('<right>', 2)
M.markdown_code_block = '<c-g>u<bs>```<cr><cr>```<cr><cr><++>' .. string.rep('<up>', 4)
function M.markdown_goto_placeholder()
  local pattern = '<++>'
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local cur_buf = vim.api.nvim_get_current_buf()
  local row_end = math.min(row + 100, vim.api.nvim_buf_line_count(cur_buf))
  local match = vim.fn.matchbufline(cur_buf, pattern, row, row_end)[1]
  if match then
    if match.lnum == row then
      return '<bs>'
        .. string.rep('<c-g>U<right>', vim.fn.strchars(vim.api.nvim_get_current_line():sub(col + 1, match.byteidx)))
        .. string.rep('<del>', #pattern)
    else
      vim.schedule(function()
        vim.api.nvim_win_set_cursor(0, { match.lnum, match.byteidx })
        util.key.feedkeys(string.rep('<del>', #pattern), 'n')
      end)
      return '<c-g>u<bs>'
    end
  else
    return 'f'
  end
end

return M
