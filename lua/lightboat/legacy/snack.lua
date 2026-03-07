local function get_compile_command(filetype, filename)
  local filename_noext = vim.fn.fnamemodify(filename, ':t:r')
  local commands = {
    c = function()
      return string.format(
        'gcc -g -Wall "%s" -I include -o "%s.out" && echo RUNNING && time "./%s.out"',
        filename,
        filename_noext,
        filename_noext
      )
    end,
    cpp = function()
      return string.format(
        'g++ -g -Wall -std=c++23 -I include "%s" -o "%s.out" && echo RUNNING && time "./%s.out"',
        filename,
        filename_noext,
        filename_noext
      )
    end,
    java = function() return string.format('javac "%s" && echo RUNNING && time java "%s"', filename, filename_noext) end,
    sh = function() return string.format('time sh "%s"', filename) end,
    bash = function() return string.format('time bash "%s"', filename) end,
    zsh = function() return string.format('time zsh "%s"', filename) end,
    python = function() return string.format('time python "%s"', filename) end,
    lua = function() return string.format('time lua "%s"', filename) end,
    go = function() return string.format('go run "%s"', filename) end,
  }
  local cmd_fn = commands[filetype]
  return cmd_fn and cmd_fn() or ''
end

M.run_single_file = function()
  local filetype = vim.bo.filetype
  if vim.tbl_contains(c.extra.markdown_fts, filetype) then
    vim.cmd('RenderMarkdown buf_toggle')
    return
  end

  local fullpath = vim.fn.expand('%:p')
  local filename = vim.fn.fnamemodify(fullpath, ':t')
  local command = get_compile_command(filetype, filename)
  if command == '' then
    vim.notify('Unsupported filetype', vim.log.levels.WARN)
    return
  end
  local directory = vim.fn.fnamemodify(fullpath, ':h')
  command = 'cd ' .. directory .. ' && ' .. command
  Snacks.terminal(command, { start_insert = true, auto_insert = true, auto_close = false })
end
