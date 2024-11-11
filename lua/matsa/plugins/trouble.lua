return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
	keys = {
		{ "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Open/close trouble list" },
		{ "<leader>xw", "<cmd>Trouble workspace_diagnostics<CR>", desc = "Open trouble workspace diagnostics" },
		{ "<leader>xd", "<cmd>Trouble document_diagnostics<CR>", desc = "Open trouble document diagnostics" },
		{ "<leader>xq", "<cmd>Trouble quickfix<CR>", desc = "Open trouble quickfix list" },
		{ "<leader>xl", "<cmd>Trouble loclist<CR>", desc = "Open trouble location list" },
		{ "<leader>xt", "<cmd>TodoTrouble<CR>", desc = "Open todos in trouble" },
	},
}
