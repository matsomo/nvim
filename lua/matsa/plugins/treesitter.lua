return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	dependencies = {
		"windwp/nvim-ts-autotag",
	},
	config = function()
		require("nvim-treesitter").setup({
			install_dir = vim.fn.stdpath("data") .. "/site",
		})

		local parsers = {
			"bash",
			"c_sharp",
			"css",
			"dockerfile",
			"gitignore",
			"go",
			"html",
			"javascript",
			"jsdoc",
			"json",
			"lua",
			"markdown",
			"markdown_inline",
			"query",
			"sql",
			"svelte",
			"tsx",
			"typescript",
			"vim",
			"vimdoc",
			"xml",
			"yaml",
		}
		require("nvim-treesitter").install(parsers)

		local filetypes = {
			"bash",
			"cs",
			"css",
			"dockerfile",
			"gitignore",
			"go",
			"help",
			"html",
			"javascript",
			"javascriptreact",
			"json",
			"lua",
			"markdown",
			"query",
			"sh",
			"sql",
			"svelte",
			"typescript",
			"typescriptreact",
			"vim",
			"xml",
			"yaml",
		}

		vim.api.nvim_create_autocmd("FileType", {
			pattern = filetypes,
			callback = function()
				pcall(vim.treesitter.start)
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})

		require("nvim-ts-autotag").setup({
			opts = {
				enable_close = true,
				enable_rename = true,
			},
		})
	end,
}
