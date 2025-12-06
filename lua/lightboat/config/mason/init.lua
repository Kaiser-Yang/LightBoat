return {
  enabled = true,
  mason_bin_first = true,
  ensure_installed = {
    -- LSP
    ['bash-language-server'] = true,
    ['clangd'] = true,
    ['shellcheck'] = true,
    ['gopls'] = true,
    ['jdtls'] = true,
    ['lua-language-server'] = true,
    ['markdown-oxide'] = true,
    ['eslint-lsp'] = true,
    ['json-lsp'] = true,
    ['lemminx'] = true,
    ['neocmakelsp'] = true,
    ['tailwindcss-language-server'] = true,
    ['typescript-language-server'] = true,
    ['vue-language-server'] = true,
    ['yaml-language-server'] = true,
    ['pyright'] = true,
    ['bazelrc-lsp'] = true,

    -- Formatters
    ['clang-format'] = true,
    ['google-java-format'] = true,
    ['stylua'] = true,
    ['prettier'] = true,
    ['buildifier'] = true,
    ['autopep8'] = true,

    -- Tools for debugging and testing
    ['java-debug-adapter'] = true,
    ['java-test'] = true,
    ['codelldb'] = true,
  },
}
