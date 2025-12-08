return {
  enabled = true,
  mason_bin_first = true,
  ensure_installed = {
    -- LSP
    ['bash-language-server'] = vim.fn.executable('bash') == 1 and vim.fn.executable('npm') == 1,
    ['clangd'] = true,
    ['shellcheck'] = vim.fn.executable('bash') == 1,
    ['gopls'] = vim.fn.executable('go') == 1,
    ['jdtls'] = vim.fn.executable('java') == 1 and vim.fn.executable('python3') == 1,
    ['lua-language-server'] = true,
    ['markdown-oxide'] = true,
    ['eslint-lsp'] = vim.fn.executable('npm') == 1,
    ['json-lsp'] = vim.fn.executable('npm') == 1,
    ['lemminx'] = vim.fn.executable('unzip') == 1,
    ['neocmakelsp'] = vim.fn.executable('cmake') == 1,
    ['tailwindcss-language-server'] = vim.fn.executable('npm') == 1,
    ['typescript-language-server'] = vim.fn.executable('npm') == 1,
    ['vue-language-server'] = vim.fn.executable('npm') == 1,
    ['yaml-language-server'] = vim.fn.executable('npm') == 1,
    ['pyright'] = vim.fn.executable('python3') == 1 and vim.fn.executable('npm'),
    ['bazelrc-lsp'] = vim.fn.executable('bazel') == 1,

    -- Formatters
    ['clang-format'] = vim.fn.executable('python3') == 1,
    ['google-java-format'] = vim.fn.executable('java') == 1 and vim.fn.executable('python3') == 1,
    ['stylua'] = vim.fn.executable('unzip') == 1,
    ['prettier'] = vim.fn.executable('npm') == 1,
    ['buildifier'] = vim.fn.executable('bazel') == 1,
    ['autopep8'] = vim.fn.executable('python3') == 1,

    -- Tools for debugging and testing
    ['java-debug-adapter'] = vim.fn.executable('java') == 1 and vim.fn.executable('python3') == 1,
    ['java-test'] = vim.fn.executable('java') == 1 and vim.fn.executable('python3') == 1,
    ['codelldb'] = true,
  },
}
