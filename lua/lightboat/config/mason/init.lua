return {
  enabled = true,
  mason_bin_first = true,
  ensure_installed = {
    -- LSP
    'bash-language-server',
    'clangd',
    'shellcheck',
    'jdtls',
    'lua-language-server',
    'markdown-oxide',
    'eslint-lsp',
    'json-lsp',
    'lemminx',
    'neocmakelsp',
    'tailwindcss-language-server',
    'typescript-language-server',
    'vue-language-server',
    'yaml-language-server',
    'pyright',
    'bazelrc-lsp',

    -- Formatters
    'clang-format',
    'google-java-format',
    'stylua',
    'prettier',
    'buildifier',
    'autopep8',

    -- Tools for debugging and testing
    'java-debug-adapter',
    'java-test',
    'codelldb',
  },
}
