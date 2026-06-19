-- Catppuccin Mocha for WezTerm
-- https://github.com/catppuccin/wezterm
return {
   foreground = "#cdd6f4",
   background = "#1e1e2e",

   cursor_bg = "#f5e0dc",
   cursor_fg = "#11111b",
   cursor_border = "#f5e0dc",

   selection_fg = "#cdd6f4",
   selection_bg = "#585b70",

   scrollbar_thumb = "#585b70",
   split = "#6c7086",

   ansi = {
      "#45475a", -- surface1 (black)
      "#f38ba8", -- red
      "#a6e3a1", -- green
      "#f9e2af", -- yellow
      "#89b4fa", -- blue
      "#f5c2e7", -- pink (magenta)
      "#94e2d5", -- teal (cyan)
      "#bac2de", -- subtext1 (white)
   },
   brights = {
      "#585b70", -- surface2 (bright black)
      "#f38ba8", -- bright red
      "#a6e3a1", -- bright green
      "#f9e2af", -- bright yellow
      "#89b4fa", -- bright blue
      "#f5c2e7", -- bright pink
      "#94e2d5", -- bright teal
      "#a6adc8", -- subtext0 (bright white)
   },
   indexed = { [16] = "#fab387", [17] = "#f5e0dc" },

   tab_bar = {
      background = "#11111b",
      active_tab = {
         bg_color = "#cba6f7",
         fg_color = "#11111b",
      },
      inactive_tab = {
         bg_color = "#181825",
         fg_color = "#cdd6f4",
      },
      inactive_tab_hover = {
         bg_color = "#1e1e2e",
         fg_color = "#cdd6f4",
      },
      new_tab = {
         bg_color = "#313244",
         fg_color = "#cdd6f4",
      },
      new_tab_hover = {
         bg_color = "#45475a",
         fg_color = "#cdd6f4",
      },
      inactive_tab_edge = "#313244",
   },
}
