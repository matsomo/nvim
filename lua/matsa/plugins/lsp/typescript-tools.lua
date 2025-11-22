return {
	"pmizio/typescript-tools.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
	config = function()
		require("typescript-tools").setup({
			-- update to this when tsgo supports import auto-imports
			-- tsserver_path = "node_modules/@typescript/native-preview/native-preview-darwin-arm64/bin/typescript-language-server",
		})
	end,
}
