return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            flavour = "macchiato",
            transparent_background = true,
        })
        vim.cmd.colorscheme("catppuccin")
    end
}

-- return {
--     "folke/tokyonight.nvim",
--     lazy = false,
--     priority = 1000,
--     config = function()
--         vim.cmd.colorscheme("tokyonight-storm")
--     end,
--     opts = {},
-- }

-- return {
--     "ellisonleao/gruvbox.nvim",
--     priority = 1000,
--     config = function()
--         require("gruvbox").setup({
--             contrast = "hard",
--             transparent_mode = true,
--         })
--         vim.cmd.colorscheme("gruvbox")
--     end,
-- }

-- return {
--     "akinsho/horizon.nvim",
--     version = "*",
--     config = function()
--         vim.cmd.colorscheme("horizon")
--         vim.o.background = "dark"
--     end
-- }

-- return {
--     'f4z3r/gruvbox-material.nvim',
--     name = 'gruvbox-material',
--     lazy = false,
--     priority = 1000,
--     opts = {
--         contrast = "hard",
--         enable_bold = 1,
--         ui_contrast = "high"
--     },
-- }

-- return {
--     "Shatur/neovim-ayu",
--     config = function()
--         require("ayu").setup({
--             mirage = false,
--             terminal = true,
--         })
--         vim.cmd.colorscheme("ayu-dark")
--     end
-- }

-- return {
--     'ray-x/aurora',
--     init = function()
--         vim.g.aurora_italic = 0
--         vim.g.aurora_transparent = 1
--         vim.g.aurora_bold = 1
--     end,
--     config = function()
--         vim.cmd.colorscheme "aurora"
--     end
-- }

-- return {
--     "sainnhe/everforest",
--     config = function()
--         vim.g.everforest_transparent_background = 2
--         vim.g.everforest_float_style = "dim"
--         vim.g.everforest_diagnostic_text_highlight = 1
--         vim.g.everforest_diagnostic_line_highlight = 1
--         vim.g.everforest_diagnostic_virtual_text = "highlighted"
--         vim.g.everforest_dim_inactive_windows = 1
--         vim.g.everforest_ui_contrast = "high"
--         vim.g.everforest_better_performans = 1
--         vim.cmd.colorscheme("everforest")
--     end
-- }
