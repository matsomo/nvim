return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
		"folke/todo-comments.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				winblend = 30,
				i = {
					["<C-k>"] = actions.move_selection_previous,
					["<C-j>"] = actions.move_selection_next,
					["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
					["<C-h>"] = "which_key",
					["<C>R"] = function(prompt_bufnr)
						local selection = actions.get_selected_entry(prompt_bufnr)
						actions.close(prompt_bufnr)
						local branch_name = selection.value:match("^[^ ]+")
						vim.cmd("!git checkout " .. branch_name)
					end,
				},
			},
		})

		telescope.load_extension("fzf")
		-- keymaps
		vim.keymap.set(
			"n",
			"<leader>ff",
			"<cmd>Telescope find_files<cr>",
			{ desc = "Fuzzy find files cwd (only git files)" }
		)
		vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
		vim.keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
		vim.keymap.set("n", "<leader>fc", function()
			local word = vim.fn.expand("<cword>")
			require("telescope.builtin").current_buffer_fuzzy_find({
				default_text = word,
				attach_mappings = function(_, map)
					map("i", "<CR>", function(prompt_bufnr)
						require("telescope.actions").select_default(prompt_bufnr)
						vim.cmd("normal! zz")
					end)
					return true
				end,
			})
		end, { desc = "Find string under cursor in current buffer" })
		vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
		vim.keymap.set(
			"n",
			"<leader>fg",
			"<cmd>Telescope git_branches --sort=comitterdate<cr>",
			{ desc = "Find git branches" }
		)

		-- colors
		local bg = "#011628"
		vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = bg })
		vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = bg })

		vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = bg })
		vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = bg })
	end,
}
