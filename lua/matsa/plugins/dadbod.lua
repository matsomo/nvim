return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true }, -- Optional
	},
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	init = function()
		-- Your DBUI configuration
		vim.g.db_ui_winwidth = 50
		vim.g.db_ui_use_nerd_fonts = 1
		vim.keymap.set("n", "<leader>db", "<cmd>DBUIToggle<cr>", { desc = "Toggle dadbod UI" })
	end,
}
