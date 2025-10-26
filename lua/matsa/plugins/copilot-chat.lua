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
			model = "claude-sonnet-4.5",
			auto_follow_cursor = false,
			window = {
				layout = "vertical",
				width = 0.5,
			},
			mappings = {
				close = {
					normal = "<Esc>",
				},
			},
			save_state = true,
			clear_chat_on_new_prompt = false,
		},
		event = "VeryLazy",
		keys = {
			{ "<leader>cp", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" },
		},
	},
}
