return {
  {
    "aserowy/tmux.nvim",
    enabled = vim.fn.has("win32") == 0,
    config = function()
      return require("tmux").setup({
        resize = {
          enable_default_keybindings = false,
        },
      })
    end,
  },
}
