return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log wrapper
		},
		build = "make tiktoken", -- Only on MacOS or Linux
		branch = "main",
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
