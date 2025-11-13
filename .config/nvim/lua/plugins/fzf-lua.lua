return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        "skim",
        fzf_opts = {
            ["--wrap"] = true,

        }
    },
    config = function()
        require("fzf-lua").setup({
            diagnostics = {
                multiline = true,
                fzf_opts = {
                    ["--wrap"] = true,
                },
            },
            winopts = {
                preview = {
                    layout = "vertical",
                }
            }
        })

        -- Register FzfLua as vim.ui.select backend
        require("fzf-lua").register_ui_select()
    end
}
