return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters = {
				csharpier = {
					append_args = {
						"--config-path",
						vim.fn.stdpath("config") .. "/resources/csharpier.yaml",
					},
				},
				prettier = {
					command = vim.fn.stdpath("data") .. "/mason/bin/prettier",
					prepend_args = {
						"--plugin",
						vim.fn.stdpath("data") .. "/mason/packages/prettier/node_modules/prettier-plugin-svelte/plugin.js",
					},
				},
				oxfmt = {
					command = vim.fn.expand("~/.vite-plus/bin/oxfmt"),
				},
			},
			formatters_by_ft = {
				javascript = { "oxfmt" },
				typescript = { "oxfmt" },
				javascriptreact = { "oxfmt" },
				typescriptreact = { "oxfmt" },
				svelte = { "prettier" }, -- oxfmt doesn't support Svelte yet
				css = { "oxfmt" },
				html = { "oxfmt" },
				json = { "oxfmt" },
				yaml = { "oxfmt" },
				lua = { "stylua" },
				cs = { "csharpier" },
			},
			format_on_save = {
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
