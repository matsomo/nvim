vim.g.mapleader = " "

vim.keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move current line up one line" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move current line down one line" })

-- file navigation
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Jump half a page up and center vertically" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Jump half a page down and center vertically" })

--window management
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })
vim.keymap.set("n", "<leader>sn", "<C-w>w", { desc = "Go to next window" })
vim.keymap.set("n", "<leader>sp", "<C-w>p", { desc = "Go to previous window" })

-- buffer history
vim.keymap.set("n", "<leader>bn", ":bn<CR>", { desc = "Go to next buffer in history" })
vim.keymap.set("n", "<leader>bp", ":bp<CR>", { desc = "Go to previous buffer in history" })

-- folding
vim.keymap.set("n", "<leader>z", "zf%", { desc = "Toggle fold with matching brackets" })

-- position correction
vim.keymap.set("i", "<Esc>", "<Esc>`^", { desc = "Keep cursor position when exiting insert mode" })
