local function default_line_wise()
  if vim.bo.filetype:match('^snack') then return 'abs' end
  return 'line_wise'
end
--- @class LightBoat.Opts.Extra.LineWise
return {
  enabled = true,
  desired_digits = '12345',
  max_len = 3,
  --- @type 'abs' | 'rel' | 'abs_rel' | 'line_wise' | 'abs_line_wise' | function():string
  insert = default_line_wise,
  --- @type 'abs' | 'rel' | 'abs_rel' | 'line_wise' | 'abs_line_wise' | function():string
  command_line = default_line_wise,
  --- @type 'abs' | 'rel' | 'abs_rel' | 'line_wise' | 'abs_line_wise' | function():string
  other = default_line_wise,
  --- @param res string The number will be shown
  format = function(res)
    if vim.bo.filetype:match('^dap') and vim.fn.winnr('$') ~= 1 then return '' end
    return string.format('%3s', res)
  end,
  keys = {
    C = { key = 'C', expr = true, desc = 'Line wise C', opts = { increase_count = true, consider_invisble = true } },
    D = { key = 'D', expr = true, desc = 'Line wise D', opts = { increase_count = true, consider_invisble = true } },
    dd = { key = 'dd', expr = true, desc = 'Line wise dd', opts = { increase_count = true, consider_invisble = true } },
    cc = { key = 'cc', expr = true, desc = 'Line wise cc', opts = { increase_count = true, consider_invisble = true } },
    J = {
      key = 'J',
      mode = { 'n', 'x' },
      expr = true,
      desc = 'Line wise J',
      opts = { increase_count = true, consider_invisble = true },
    },
    j = {
      key = 'j',
      mode = { 'n', 'x', 'o' },
      desc = 'Line wise j',
      expr = true,
      opts = {
        consider_wrap = function() return vim.fn.mode():find('o') == nil and vim.bo.filetype ~= 'qf' end,
        increase_count = false,
        consider_invisble = true,
      },
    },
    k = {
      key = 'k',
      mode = { 'n', 'x', 'o' },
      expr = true,
      desc = 'Line wise k',
      opts = {
        consider_wrap = function() return vim.fn.mode():find('o') == nil and vim.bo.filetype ~= 'qf' end,
        increase_count = false,
        consider_invisble = true,
      },
    },
  },
}
