return {
  type = 'executable',
  command = 'codelldb',
  detached = vim.fn.has('win32') == 0,
}
