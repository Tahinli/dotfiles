return {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },

    opts = {
        servers = {
            lua_ls = {}
        }
    },

    config = function()
        local capabilities = require("blink.cmp").get_lsp_capabilities()
        local lspconfig = require("lspconfig")

        lspconfig["lua_ls"].setup({ capabilities = capabilities })
        lspconfig["clangd"].setup({ capabilities = capabilities })
        lspconfig["pyright"].setup({
            settings = {
                pyright = {
                    disableOrganizeImpors = true,
                },
                python = {
                    analysis = {
                        ignore = { "*" }
                    }
                }
            },
            capabilities = capabilities
        })
        lspconfig["ruff"].setup({
            init_options = {
                settings = {
                    logLevel = "trace",
                },
            },
            capabilities = capabilities,
        })
        lspconfig["cssls"].setup({ capabilities = capabilities })
    end
}
