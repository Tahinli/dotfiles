return {
    "saghen/blink.cmp",
    build = "cargo build --release",
    opts = {
        keymap = {
            ["<cr>"] = { "accept", "fallback" },
            ["<S-Up>"] = { "scroll_documentation_up", "fallback" },
            ["<S-Down>"] = { "scroll_documentation_down", "fallback" },
        },
        appearance = {
            nerd_font_variant = "normal"
        },
        completion = {
            ghost_text = {
                enabled = false,
            },
            list = {
                selection = {
                    preselect = false,
                    auto_insert = false,
                },
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 300,
            },
            menu = {
                auto_show = true,
                draw = {
                    treesitter = {
                        "lsp"
                    },
                },
            },
        },
        signature = {
            enabled = true,
        },
    },
}
