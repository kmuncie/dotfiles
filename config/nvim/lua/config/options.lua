-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
local opt = vim.opt

-- UI settings
opt.title = true
opt.number = true
opt.relativenumber = true
opt.ruler = true -- Show cursor position
opt.wrap = true -- Wrap lines
opt.textwidth = 90
opt.colorcolumn = "+1" -- Show column one character after textwidth
opt.wrapmargin = 0
opt.showcmd = true
opt.ttimeoutlen = 50

-- Text editing
opt.autoindent = true
opt.tabstop = 8
opt.softtabstop = 3
opt.shiftwidth = 3
opt.expandtab = true
opt.backspace = "indent,eol,start"

-- GUI options (for Neovide or other GUI clients)
-- opt.guioptions = "T" -- Enable toolbar

-- LazyVim typically already sets these, but you can override them:
opt.termguicolors = true -- Enable true color support
opt.mouse = "a" -- Enable mouse support
opt.signcolumn = "yes" -- Always show sign column
opt.updatetime = 300 -- Faster completion
