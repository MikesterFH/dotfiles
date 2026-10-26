-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Set navigation here, after LazyVim's default window mappings.
if vim.env.TMUX then
  keymap.set("n", "<C-h>", "<Cmd>NvimTmuxNavigateLeft<CR>", { silent = true })
  keymap.set("n", "<C-j>", "<Cmd>NvimTmuxNavigateDown<CR>", { silent = true })
  keymap.set("n", "<C-k>", "<Cmd>NvimTmuxNavigateUp<CR>", { silent = true })
  keymap.set("n", "<C-l>", "<Cmd>NvimTmuxNavigateRight<CR>", { silent = true })
  keymap.set("n", "<C-\\>", "<Cmd>NvimTmuxNavigateLastActive<CR>", { silent = true })
  keymap.set("n", "<C-Space>", "<Cmd>NvimTmuxNavigateNavigateNext<CR>", { silent = true })
else
  local splits = require("smart-splits")
  keymap.set("n", "<C-h>", splits.move_cursor_left, { desc = "Go to left window", silent = true })
  keymap.set("n", "<C-j>", splits.move_cursor_down, { desc = "Go to lower window", silent = true })
  keymap.set("n", "<C-k>", splits.move_cursor_up, { desc = "Go to upper window", silent = true })
  keymap.set("n", "<C-l>", splits.move_cursor_right, { desc = "Go to right window", silent = true })
end

-- escape alternative
keymap.set({ "i" }, "jj", "<Esc>", { silent = true })

-- Terminal in root dir
vim.keymap.set("n", "<C-/>", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (root dir)" })

-- Git graph in floating window (paged via less, close with q)
vim.keymap.set("n", "<leader>gG", function()
  local graph = "git-graph --color always --style round"
  local cmd
  if vim.fn.has("win32") == 1 then
    local less = vim.fn.exepath("less")
    if less == "" then
      less = vim.fn.fnamemodify(vim.fn.exepath("git"), ":h:h") .. "/usr/bin/less.exe"
    end
    cmd = { "cmd", "/c", graph .. ' | "' .. less .. '" -R -S' }
  else
    cmd = { "sh", "-c", graph .. " | less -R -S" }
  end
  Snacks.terminal(cmd, {
    cwd = LazyVim.root.git(),
    env = { LESSCHARSET = "utf-8" },
    win = {
      position = "float",
      border = "rounded",
      width = 0.9,
      height = 0.9,
    },
  })
end, { desc = "Git Graph (root dir)" })

-- delete some keymaps
pcall(keymap.del, { "n", "i", "v" }, "<A-j>")
pcall(keymap.del, { "n", "i", "v" }, "<A-k>")
pcall(keymap.del, "n", "<C-Left>")
pcall(keymap.del, "n", "<C-Down>")
pcall(keymap.del, "n", "<C-Up>")
pcall(keymap.del, "n", "<C-Right>")

-- Resize panes without tmux.nvim's synchronous shell calls on Windows.
if vim.fn.has("win32") == 1 then
  for key, direction in pairs({ h = "L", j = "D", k = "U", l = "R" }) do
    keymap.set("n", "<M-" .. key .. ">", function()
      if not vim.env.TMUX or not vim.env.TMUX_PANE then
        vim.notify("Pane resizing requires a psmux session", vim.log.levels.WARN)
        return
      end
      vim.system({
        "psmux",
        "-S",
        vim.env.TMUX:match("^[^,]+"),
        "resize-pane",
        "-t",
        vim.env.TMUX_PANE,
        "-" .. direction,
        "1",
      }, { text = true }, function(result)
        if result.code ~= 0 then
          vim.schedule(function()
            vim.notify("psmux resize failed: " .. (result.stderr or result.stdout or ""), vim.log.levels.ERROR)
          end)
        end
      end)
    end, { silent = true })
  end
else
  keymap.set("n", "<M-h>", '<Cmd>lua require("tmux").resize_left()<CR>', { silent = true })
  keymap.set("n", "<M-j>", '<Cmd>lua require("tmux").resize_bottom()<CR>', { silent = true })
  keymap.set("n", "<M-k>", '<Cmd>lua require("tmux").resize_top()<CR>', { silent = true })
  keymap.set("n", "<M-l>", '<Cmd>lua require("tmux").resize_right()<CR>', { silent = true })
end

-- Split windows
keymap.set("n", "ss", ":vsplit<Return>", opts)
keymap.set("n", "sv", ":split<Return>", opts)

-- Tabs
keymap.set("n", "te", ":tabedit", opts)
keymap.set("n", "<tab>", ":tabnext<Return>", opts)
keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)
