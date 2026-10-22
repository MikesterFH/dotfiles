return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = { auto_show = false, border = "rounded" },
        documentation = { window = { border = "rounded" } },
      },
      keymap = {
        -- Enter inserts a newline, completion is accepted with <C-y> (preset) or <Tab>
        ["<CR>"] = {},
        ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
      },
    },
  },
}
