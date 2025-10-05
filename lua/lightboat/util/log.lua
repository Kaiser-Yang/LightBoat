local M = {}

M.level = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
}

M.level_name = {
  [M.level.DEBUG] = 'DEBUG',
  [M.level.INFO] = 'INFO',
  [M.level.WARN] = 'WARN',
  [M.level.ERROR] = 'ERROR',
}

M.current_level = M.level.INFO

M.filepath = vim.fn.stdpath('log') .. '/lightboat.log'

local function _write(level, msg)
  if level < M.current_level then return end
  local f, err = io.open(M.filepath, 'a')
  if not f then
    vim.notify(string.format('Failed to open log file %s: %s', M.filepath, err), vim.log.levels.ERROR)
    return
  end
  f:write(
    string.format(
      '[%s][%s][%s] %s\n',
      vim.g.vscode and 'VSCODE' or 'NEOVIM',
      os.date('%Y-%m-%d %H:%M:%S'),
      M.level_name[level],
      msg
    )
  )
  f:close()
end

--- @param msg string
function M.debug(msg) _write(M.level.DEBUG, msg) end

--- @param msg string
function M.info(msg) _write(M.level.INFO, msg) end

--- @param msg string
function M.warn(msg) _write(M.level.WARN, msg) end

--- @param msg string
function M.error(msg) _write(M.level.ERROR, msg) end

function M.set_level(level) M.current_level = level end

--- @param filepath string
function M.set_file(filepath)
  if filepath:match('^%s*$') then vim.notify('Empty filepath to log', vim.log.levels.ERROR) end
  M.filepath = filepath
end

return M
