return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = function()
		require("nvim-treesitter").install({
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
		})
	end,
	dependencies = {
		"windwp/nvim-ts-autotag",
	},
	config = function()
		require("nvim-treesitter").setup()

		-- The main branch stores queries under runtime/ which needs to be on the rtp
		local ts_plugin = vim.api.nvim_get_runtime_file("lua/nvim-treesitter", false)[1]
		if ts_plugin then
			local ts_runtime = vim.fn.fnamemodify(ts_plugin, ":h:h") .. "/runtime"
			if vim.uv.fs_stat(ts_runtime) and not vim.list_contains(vim.opt.rtp:get(), ts_runtime) then
				vim.opt.rtp:prepend(ts_runtime)
			end
		end

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
