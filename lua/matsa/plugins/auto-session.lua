return {
	"rmagatti/auto-session",
	config = function()
		local auto_session = require("auto-session")

		auto_session.setup({
			auto_restore_enabled = true,
			auto_session_suppress_dirs = { "~/", "~/Dev", "Downloads", "~/Documents", "~/Desktop/" },

			session_lens = {
				buftypes_to_ignore = {},
				load_on_setup = true,
				theme_conf = { border = true },
				previewer = false,
			},
		})

		vim.keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
		vim.keymap.set("n", "<leader>ws", "<cmd>SessionSave<CR>", { desc = "Save session for auto session root dir" })
		vim.keymap.set(
			"n",
			"<leader>wl",
			require("auto-session.session-lens").search_session,
			{ desc = "List sessions", noremap = true }
		)
	end,
}
