return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "canary",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		opts = {
			auto_follow_cursor = false,
			window = {
				layout = "float",
				height = 0.8,
				width = 0.6,
			},
			mappings = {
				close = {
					normal = "<Esc>",
				},
			},
		},
		event = "VeryLazy",
		keys = {
			{ "<leader>cp", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" },
		},
	},
}
