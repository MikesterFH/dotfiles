return {
  -- markdownlint: Zeilenlänge (MD013) & Co. abschalten, die bei Fliesstext nur nerven
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local cfg = vim.fn.stdpath("config") .. "/markdownlint.jsonc"
      local linter = require("lint").linters["markdownlint-cli2"]
      linter.args = { "--config", cfg, "--" }
      return opts
    end,
  },
}
