local operation = {
  ['<c-a>'] = function()
      local ok, noice_config = pcall(require, 'noice.config')
      if not ok then return '<home>' end
      local format = noice_config.defaults().cmdline.format
      if not format then return '<home>' end
      local line = vim.fn.getcmdtype() .. vim.fn.getcmdline()
      local matched = nil
      for _, v in pairs(format) do
        local ps = type(v.pattern) == 'table' and v.pattern or { v.pattern }
        for _, p in ipairs(ps) do
          if p and type(p) == 'string' then
            local cur_matched = line:match(p)
            if not matched or cur_matched and #cur_matched > #matched then matched = cur_matched end
          end
        end
      end
      if matched then
        return '<home>' .. string.rep('<right>', #matched - 1)
      else
        return '<home>'
      end
  end,
}
