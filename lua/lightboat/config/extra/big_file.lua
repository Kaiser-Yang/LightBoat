--- @type LightBoat.BigFileOpt
return {
  enabled = true,
  total = 5 * 1024 * 1024, -- 5 MB
  every_line = 1 * 1024, -- 1 KB
  on_changed = function(buffer)
    if not vim.b[buffer].big_file_status then return end
  end,
}
