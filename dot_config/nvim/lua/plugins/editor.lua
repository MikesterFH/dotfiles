return {
  -- TODO not working
  -- {
  --   "lewis6991/gitsigns.nvim",
  -- },
  {
    "folke/todo-comments.nvim",
  },
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = {
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    },
  },
}
