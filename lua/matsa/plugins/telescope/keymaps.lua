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

	-- Reverse of <leader>ff: files NOT tracked by git (untracked + gitignored),
	-- e.g. agent docs (.claude/…) and local dev configs (.env, secrets). We list
	-- files with fd (hidden + ignored), then subtract git-tracked ones. In a
	-- non-git dir nothing is tracked, so everything shows — the correct meaning
	-- of "not tracked" there. Heavy build/cache dirs are excluded at the source
	-- so fd stays fast and results aren't drowned (e.g. .yarn/cache = thousands).
	vim.keymap.set("n", "<leader>fu", function()
		-- Dirs excluded everywhere: build output, dependency + tool caches.
		local exclude = {
			".git",
			"node_modules",
			".next",
			"dist",
			"build",
			"target",
			"obj",
			"bin",
			".venv",
			".yarn",
			".turbo",
			".cache",
			".nx",
			"coverage",
		}

		local fd = { "fd", "--type", "f", "--hidden", "--no-ignore" }
		for _, e in ipairs(exclude) do
			table.insert(fd, "--exclude")
			table.insert(fd, e)
		end

		local files = vim.fn.systemlist(fd)
		if vim.v.shell_error ~= 0 then
			vim.notify("fd failed (is fd installed?)", vim.log.levels.ERROR)
			return
		end

		if vim.fn.systemlist({ "git", "rev-parse", "--is-inside-work-tree" })[1] == "true" then
			local tracked = {}
			for _, f in ipairs(vim.fn.systemlist({ "git", "ls-files" })) do
				tracked[f] = true
			end
			files = vim.tbl_filter(function(f)
				return not tracked[f]
			end, files)
		end

		if vim.tbl_isempty(files) then
			vim.notify("No untracked/ignored files found", vim.log.levels.INFO)
			return
		end

		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local make_entry = require("telescope.make_entry")

		pickers
			.new({}, {
				prompt_title = "Files not tracked by git",
				finder = finders.new_table({
					results = files,
					entry_maker = make_entry.gen_from_file({}),
				}),
				sorter = conf.file_sorter({}),
				previewer = conf.file_previewer({}),
			})
			:find()
	end, { desc = "Fuzzy find files not tracked by git" })

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

	vim.keymap.set("n", "<leader>fg", "<cmd>Telescope git_branches<cr>", { desc = "Find git branches" })

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
