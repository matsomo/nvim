return {
	"numToStr/Comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	config = function()
		-- import comment plugin safely
		local comment = require("Comment")

		local ts_pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()

		-- enable comment
		comment.setup({
			-- for commenting tsx, jsx, svelte, html files
			pre_hook = function(ctx)
				-- nvim 0.12 get_parser returns nil (instead of erroring) for filetypes
				-- without a parser (e.g. .env), which crashes Comment.nvim's treesitter
				-- fallback; use the native commentstring for those instead
				if not vim.treesitter.get_parser(0, nil, { error = false }) then
					return require("Comment.ft").get(vim.bo.filetype, ctx.ctype) or vim.bo.commentstring
				end
				return ts_pre_hook(ctx)
			end,
		})

		-- keymaps
		-- gc + navigation : comment out specified lines
		-- gcc : comment out current line
	end,
}
