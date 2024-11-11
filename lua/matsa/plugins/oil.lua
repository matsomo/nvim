return {
	"stevearc/oil.nvim",
	config = function()
		require("oil").setup({
			default_file_explorer = true,
			skip_confirm_for_simple_edits = false,
			use_default_keymaps = true,
			view_options = {
				-- Show files and directories that start with "."
				show_hidden = true,
			},

			-- keymaps
			vim.api.nvim_set_keymap("n", "<leader>o", ":Oil<CR>", { desc = "Open oil", noremap = true, silent = true }),
		})
	end,
}
