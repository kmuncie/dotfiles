-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps hereby
--
vim.keymap.set("i", "ii", "<Esc>", { desc = "Escape shortcut" })
vim.keymap.set("n", "Y", "y$", { desc = "Yank to end of line" })
