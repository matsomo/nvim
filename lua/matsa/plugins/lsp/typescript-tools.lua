return {
	"pmizio/typescript-tools.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
	config = function()
		require("typescript-tools").setup({
			tsserver_max_ts_server_memory = 4096, -- increase memory if needed
			typescript = {
				suggest = {
					autoImports = true,
				},
			},

			-- tsserver_path = "tsgo", -- use this when tsgo is ready
		})
		vim.keymap.set(
			"n",
			"<leader>ci",
			"<cmd>TSToolsAddMissingImports<cr>",
			{ desc = "Add all missing imports for file" }
		)
	end,
}
