-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.relativenumber = true
-- opt.tapstop = 4 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard

-- Rechtschreibung: Deutsch + Englisch (Wörterbuch wird bei Bedarf automatisch geladen)
opt.spelllang = { "de", "en" }

-- disable unused providers (silences :checkhealth warnings)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
