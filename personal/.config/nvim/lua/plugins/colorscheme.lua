return {
   {
      "scottmckendry/cyberdream.nvim",
      -- "folke/tokyonight.nvim",
      lazy = false, -- make sure we load this during startup
      priority = 1000, -- make sure to load this before all the other start plugins
      config = function()
         require("cyberdream").setup({
            transparent = true,
         })
         vim.cmd("colorscheme cyberdream")
      end,
   },
}
