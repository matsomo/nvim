-- Telescope keymaps
local M = {}

-- Pickers that list/grep the whole repo can hang or crash nvim on huge repos
-- if they start the moment they open. They wait for this many characters.
local MIN_CHARS = 3

-- Wraps a finder factory so the underlying job is only created (and started)
-- once the prompt reaches MIN_CHARS. The inner finder is created once and then
-- reused, so a oneshot job still runs a single time and fuzzy-sorts from there.
local function min_chars_finder(make_finder)
	local inner
	return setmetatable({
		close = function()
			if inner then
				inner:close()
			end
		end,
	}, {
		__index = function(_, key)
			return inner and inner[key] or nil
		end,
		__call = function(_, prompt, process_result, process_complete)
			if #(prompt or "") < MIN_CHARS then
				process_complete()
				return
			end
			inner = inner or make_finder()
			return inner(prompt, process_result, process_complete)
		end,
	})
end

-- File picker backed by a shell command that only runs after MIN_CHARS.
local function gated_file_picker(title, command)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local make_entry = require("telescope.make_entry")

	pickers
		.new({}, {
			prompt_title = string.format("%s (type %d+ chars)", title, MIN_CHARS),
			finder = min_chars_finder(function()
				return finders.new_oneshot_job(command, { entry_maker = make_entry.gen_from_file({}) })
			end),
			sorter = conf.file_sorter({}),
			previewer = conf.file_previewer({}),
		})
		:find()
end

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
	vim.keymap.set("n", "<leader>ff", function()
		gated_file_picker("Find Files", { "rg", "--files", "--color", "never" })
	end, { desc = "Fuzzy find files cwd (only git files)" })

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

		if vim.fn.executable("fd") == 0 then
			vim.notify("fd is not installed", vim.log.levels.ERROR)
			return
		end

		local fd = { "fd", "--type", "f", "--hidden", "--no-ignore", "--color", "never" }
		for _, e in ipairs(exclude) do
			table.insert(fd, "--exclude")
			table.insert(fd, e)
		end

		-- fd output minus git-tracked files, run async once MIN_CHARS is typed.
		-- Outside a git repo `git ls-files` prints nothing, so everything shows.
		local fd_cmd = table.concat(vim.tbl_map(vim.fn.shellescape, fd), " ")
		local script = string.format(
			"comm -23 <(%s | LC_ALL=C sort) <(git ls-files 2>/dev/null | LC_ALL=C sort)",
			fd_cmd
		)
		gated_file_picker("Files not tracked by git", { "bash", "-c", script })
	end, { desc = "Fuzzy find files not tracked by git" })

	vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })

	vim.keymap.set("n", "<leader>fs", function()
		require("telescope.builtin").live_grep({
			prompt_title = string.format("Live Grep (type %d+ chars)", MIN_CHARS),
			-- live_grep skips running rg for an empty prompt, so hide short ones.
			on_input_filter_cb = function(prompt)
				if #prompt < MIN_CHARS then
					return { prompt = "" }
				end
			end,
		})
	end, { desc = "Find string in cwd" })

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
