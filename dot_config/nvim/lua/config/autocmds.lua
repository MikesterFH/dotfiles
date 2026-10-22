-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Spellcheck in Markdown standardmässig aus (Toggle: <leader>us)
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("markdown_no_spell", { clear = true }),
  pattern = { "markdown", "text" },
  callback = function()
    vim.opt_local.spell = false
  end,
})
