-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- 保存
vim.keymap.set("n", "<C-s>", ":w<CR>")
-- 清除高亮
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")
-- 更快的窗口切换（不依赖 tmux）
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
