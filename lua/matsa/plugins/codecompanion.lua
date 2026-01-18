return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/mcphub.nvim",
	},
	event = "VeryLazy",
	config = function()
		require("codecompanion").setup({
			extensions = {
				mcphub = {
					callback = "mcphub.extensions.codecompanion",
					opts = {
						make_vars = true,
						make_slash_commands = true,
						show_result_in_chat = true,
					},
				},
			},
		})
	end,
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
		interactions = {
			chat = {
				adapter = {
					name = "claude_code",
					model = "opus",
					sources = {
						buffer = {
							type = "buffers",
						},
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
