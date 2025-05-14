require 'nvim-treesitter.configs'.setup {
    ensure_installed = { "c", "cpp", "python", "html", "css", "javascript", "java", "bash", "lua", "rust", "vim" },
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,
    },
}
