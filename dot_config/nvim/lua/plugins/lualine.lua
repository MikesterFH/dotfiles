return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    table.insert(opts.sections.lualine_c, {
      function()
        return require("package-info").get_status()
      end,
      cond = function()
        return package.loaded["package-info"] ~= nil
      end,
      color = function()
        return { fg = Snacks.util.color("Statement") }
      end,
    })
  end,
}
