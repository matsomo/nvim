return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				svelte = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				-- markdown = { "prettier" },
				lua = { "stylua" },
			},
			format_on_save = {
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			},
		})

		-- Custom formatter args
		require("conform.formatters.prettier").args = function(self, ctx)
			local prettier_roots = { ".prettierrc", ".prettierrc.json", "prettier.config.js" }
			local args = { "--stdin-filepath", "$FILENAME" }

			local localPrettierConfig = vim.fs.find(prettier_roots, {
				upward = true,
				path = ctx.dirname,
				type = "file",
			})[1]

			local globalPrettierConfig = vim.fs.find(prettier_roots, {
				path = vim.fn.stdpath("config"),
				type = "file",
			})[1]

			local disableGlobalPrettierConfig = os.getenv("DISABLE_GLOBAL_PRETTIER_CONFIG")

			-- Project config takes precedence over global config
			if localPrettierConfig then
				vim.list_extend(args, { "--config", localPrettierConfig })
			elseif globalPrettierConfig and not disableGlobalPrettierConfig then
				vim.list_extend(args, { "--config", globalPrettierConfig })
			end

			return args
		end

		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
