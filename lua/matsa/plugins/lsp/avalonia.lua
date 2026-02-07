return {
	"neovim/nvim-lspconfig",
	opts = function()
		-- Configure filetype detection for .axaml files
		vim.filetype.add({
			extension = {
				axaml = "xml",
			},
		})

		-- Start Avalonia Language Server for .axaml files
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			pattern = { "*.axaml" },
			callback = function(event)
				vim.lsp.start({
					name = "avalonia",
					cmd = { "avalonia-ls" },
					root_dir = vim.fn.getcwd(),
					filetypes = { "xml" },
				})
			end,
		})
	end,
}
