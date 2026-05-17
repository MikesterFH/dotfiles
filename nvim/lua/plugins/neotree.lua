return {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
        window = {
            position = "right",
            mappings = {
                ["Y"] = "none",
            },
        },
        filesystem = {
            filtered_items = {
                visible = true,
            },
        },
    },
}
