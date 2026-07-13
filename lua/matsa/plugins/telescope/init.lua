return {
	"nvim-telescope/telescope.nvim",
	branch = "master",
	event = "VeryLazy",
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
					preview_width = 0.4,
				},
				mappings = {
					i = {
						["<C-t>"] = open_with_trouble,
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						["<C-h>"] = "which_key",
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

		-- Highlight customization: keep Telescope's floating windows matching the
		-- active theme's background (borderless look) in both light and dark.
		-- Re-applied on every colorscheme change so it follows <leader>tt.
		local function sync_telescope_hl()
			local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
			local bg = normal.bg and string.format("#%06x", normal.bg) or "NONE"
			vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = bg })
			vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = bg })
			vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = bg })
			vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = bg })
			vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = bg })
		end

		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("TelescopeThemeSync", { clear = true }),
			callback = sync_telescope_hl,
		})
		sync_telescope_hl()
	end,
}
