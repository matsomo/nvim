return {
	"sindrets/diffview.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
	opts = {
		hooks = {
			-- Added/deleted files have nothing to diff against: collapse the
			-- empty (null-buffer) pane to a sliver so the file gets the width.
			-- Closing the window instead would crash diffview's scroll-sync.
			diff_buf_win_enter = function(bufnr, winid, ctx)
				if ctx.layout_name == "diff2_horizontal" then
					if vim.api.nvim_buf_get_name(bufnr) == "diffview://null" then
						vim.api.nvim_win_set_width(winid, 1)
					elseif ctx.symbol == "a" then
						-- the "a" pane opens first, so equalizing here never
						-- undoes a collapse done by the "b" pane
						vim.api.nvim_win_call(winid, function()
							vim.cmd("wincmd =")
						end)
					end
				end
			end,
		},
		keymaps = {
			view = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
			},
			file_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
			},
			file_history_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
			},
		},
	},
}
