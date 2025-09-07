local format_and_save = function()
    vim.lsp.buf.format()
    vim.cmd.update()
end

vim.keymap.set("n", "<C-o>", require("fzf-lua").live_grep_native, {})
vim.keymap.set("n", "<C-l>", require("fzf-lua").buffers, {})
vim.keymap.set("n", "<C-k>", require("fzf-lua").lsp_definitions, {})
vim.keymap.set("n", "\"m", require("fzf-lua").manpages, {})
vim.keymap.set("n", "z.", require("fzf-lua").spell_suggest, {})
vim.keymap.set("n", ".", require("fzf-lua").lsp_code_actions, {
    noremap = true, silent = true,
})
vim.keymap.set("n", ",", function() vim.diagnostic.open_float() end, {})
vim.keymap.set("n", "\"r", function() vim.lsp.buf.rename() end, {})
vim.keymap.set("n", ";", require("fzf-lua").diagnostics_workspace, {})


vim.keymap.set({ "n", "i", "v" }, "<C-s>", format_and_save)
vim.keymap.set({ "n", "v" }, "-", "<cmd>Oil<CR>", { noremap = true, silent = true, })
-- terminal exit close remap
vim.keymap.set("t", "<ESC>e", "<C-\\><C-n>", { noremap = true })

vim.keymap.set("n", "<F5>", function() require("dap").continue() end)
vim.keymap.set("n", "<F10>", function() require("dap").step_over() end)
vim.keymap.set("n", "<F11>", function() require("dap").step_into() end)
vim.keymap.set("n", "<F12>", function() require("dap").step_out() end)
vim.keymap.set("n", "\"db", function() require("dap").toggle_breakpoint() end)
vim.keymap.set("n", "\"dl", function() require("dap").run_last() end)
vim.keymap.set({ "n", "v" }, "\"dh", function()
    require("dap.ui.widgets").hover()
end)

vim.keymap.set("n", "<Space>cv", require("crates").show_versions_popup, {})
vim.keymap.set("n", "<Space>cf", require("crates").show_features_popup, {})
vim.keymap.set("n", "<Space>cd", require("crates").show_dependencies_popup, {})
