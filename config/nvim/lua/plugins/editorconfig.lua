return {
   {
      "editorconfig/editorconfig-vim",
      event = { "BufReadPre", "BufNewFile" },
      config = function()
         -- Ensure editorconfig works well with fugitive
         vim.g.EditorConfig_exclude_patterns = { "fugitive://.*" }
      end,
   },
}
