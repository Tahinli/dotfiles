return {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false,
    config = function()
        vim.g.rustaceanvim = {
            tools = {
                enable_clippy = false,
            },
        }
    end
}
