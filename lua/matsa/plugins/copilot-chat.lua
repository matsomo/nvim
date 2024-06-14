return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "canary",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		opts = {
			debug = true, -- Enable debugging
		},
		event = "VeryLazy",
		keys = {
			{ "<leader>cp", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" },
			{ "<leader>cs", "<cmd>CopilotChatSave<cr>", desc = "CopilotChat - Save to trigger response" },
		},
	},
}
