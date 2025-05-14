require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = {
        "lua_ls",
        "basedpyright",
        "clangd",
        "bashls",
        "jdtls",
        "html",
        "cssls",
        "ts_ls"
    }
})

local lspconfig = require("lspconfig")

lspconfig.lua_ls.setup {}
lspconfig.basedpyright.setup {}
lspconfig.clangd.setup {}
lspconfig.bashls.setup {}
lspconfig.jdtls.setup {}
lspconfig.html.setup {}
lspconfig.cssls.setup {}
lspconfig.ts_ls.setup {}
