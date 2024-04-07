vim.g.mapleader = " ";

vim.keymap.set("n", "<leader>eo", vim.cmd.Ex, { desc = "Open file explorer" });
vim.keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" });
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Map ctrl + c to Esc" });

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move current line up one line" });
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move current line down one line" });

-- file navigation
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Jump half a page up and center vertically" });
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Jump half a page down and center vertically" });

--window management
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" });
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" });
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" });
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" });

-- tabs
vim.keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" });
vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" });
vim.keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" });
vim.keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" });
vim.keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" });
