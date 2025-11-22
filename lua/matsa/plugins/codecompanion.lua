return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	cmd = {
		"CodeCompanion",
		"CodeCompanionChat",
		"CodeCompanionActions",
		"CodeCompanionToggle",
		"CodeCompanionAdd",
	},
	keys = {
		{
			"<leader>cc",
			"<cmd>CodeCompanionChat Toggle<cr>",
			desc = "CodeCompanion - Toggle chat",
			mode = { "n", "v" },
		},
	},
	opts = {
		strategies = {
			chat = {
				name = "copilot",
				model = "GPT-5.1",
				sources = {
					buffer = {
						type = "buffers",
					},
				},
			},
		},
		-- NOTE: The log_level is in `opts.opts`
		opts = {
			log_level = "DEBUG",
		},
		display = {
			chat = {
				window = {
					layout = "vertical", -- or "horizontal", "float"
					width = 0.45,
					height = 0.8,
					relative = "editor",
					border = "rounded",
				},
			},
		},
	},
}
