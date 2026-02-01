-- Telescope keymaps
local M = {}

function M.setup()
	-- Image clearing keymap
	vim.keymap.set("n", "<leader>ic", function()
		local ok, image = pcall(require, "image")
		if ok then
			pcall(function()
				image.clear()
			end)
			pcall(function()
				local images = image.get_images()
				for _, img in ipairs(images) do
					img:clear()
				end
			end)
			vim.defer_fn(function()
				vim.cmd("mode")
			end, 50)
			vim.notify("Cleared all images", vim.log.levels.INFO)
		else
			vim.notify("image.nvim not loaded", vim.log.levels.WARN)
		end
	end, { desc = "Clear all images" })

	-- Telescope pickers
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

	-- Next.js route pattern grep
	vim.keymap.set("n", "<leader>fp", function()
		require("telescope.builtin").live_grep({
			prompt_title = "Next.js Route Pattern",
			on_input_filter_cb = function(prompt)
				-- Transform all ${...} into \${[^}]+}
				local pattern = prompt:gsub("%${[^}]+}", "\\${[^}]+}")
				return { prompt = pattern }
			end,
			additional_args = function()
				return { "--pcre2" }
			end,
		})
	end, { desc = "Grep for Next.js route pattern" })
end

return M
