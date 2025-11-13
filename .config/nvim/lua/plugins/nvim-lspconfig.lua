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

        -- Configure servers using the new vim.lsp.config API
        vim.lsp.config("lua_ls", {
            capabilities = capabilities,
        })

        vim.lsp.config("clangd", {
            capabilities = capabilities,
        })

        vim.lsp.config("pyright", {
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
            capabilities = capabilities,
        })

        vim.lsp.config("ruff", {
            init_options = {
                settings = {
                    logLevel = "trace",
                },
            },
            capabilities = capabilities,
        })

        vim.lsp.config("cssls", {
            capabilities = capabilities,
        })

        vim.lsp.config("html", {
            capabilities = capabilities,
        })

        vim.lsp.config("ts_ls", {
            capabilities = capabilities,
        })

        -- Enable all configured servers
        vim.lsp.enable("lua_ls")
        vim.lsp.enable("clangd")
        vim.lsp.enable("pyright")
        vim.lsp.enable("ruff")
        vim.lsp.enable("cssls")
        vim.lsp.enable("html")
        vim.lsp.enable("ts_ls")
    end
}
