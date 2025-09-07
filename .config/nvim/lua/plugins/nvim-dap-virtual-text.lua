return {
    "theHamsta/nvim-dap-virtual-text",
    config = function()
        require("nvim-dap-virtual-text").setup({
            all_references = true,
            only_first_definition = false,
            highlight_new_as_changed = true,
        })
    end
}
