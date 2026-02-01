return {
	"nvim-telescope/telescope.nvim",
	branch = "master",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
		"folke/todo-comments.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local open_with_trouble = require("trouble.sources.telescope").open
		local image_preview = require("matsa.plugins.telescope.image-preview")
		local keymaps = require("matsa.plugins.telescope.keymaps")

		-- Telescope setup
		telescope.setup({
			defaults = {
				buffer_previewer_maker = image_preview.buffer_previewer_maker,
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden",
					"--trim",
					"--multiline",
				},
				winblend = 30,
				layout_config = {
					width = 0.95,
					preview_width = 0.6,
				},
				mappings = {
					i = {
						["<C-t>"] = open_with_trouble,
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
						["<S-Up>"] = actions.cycle_history_prev,
						["<S-Down>"] = actions.cycle_history_next,
					},
				},
			},
		})

		-- Load extensions
		telescope.load_extension("fzf")

		-- Setup image preview cleanup
		image_preview.setup_cleanup_autocmds()

		-- Setup keymaps
		keymaps.setup()

		-- Highlight customization
		local bg = "#011628"
		vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = bg })
		vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = bg })
		vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = bg })
		vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = bg })
	end,
}
