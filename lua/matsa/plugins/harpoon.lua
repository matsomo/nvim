return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
	config = function()
		local harpoon = require("harpoon")

		-- REQUIRED
		harpoon:setup()
		-- REQUIRED

		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end, { desc = "Add file to list" })
		-- vim.keymap.set("n", "<C-e>", function()
		-- 	harpoon.ui:toggle_quick_menu(harpoon:list())
		-- end, { desc = "Open Harpoon window"})

		vim.keymap.set("n", "<leader>qj", function()
			harpoon:list():select(1)
		end, { desc = "Go to file 1" })
		vim.keymap.set("n", "<leader>qk", function()
			harpoon:list():select(2)
		end, { desc = "Go to file 2" })
		vim.keymap.set("n", "<leader>ql", function()
			harpoon:list():select(3)
		end, { desc = "Go to file 3" })
		vim.keymap.set("n", "<leader>q;", function()
			harpoon:list():select(4)
		end, { desc = "Go to file 4" })

		vim.keymap.set("n", "<leader>Qj", function()
			harpoon:list():replace_at(0)
		end, { desc = "Replace file 1" })
		vim.keymap.set("n", "<leader>Qk", function()
			harpoon:list():replace_at(2)
		end, { desc = "Replace file 2" })
		vim.keymap.set("n", "<leader>Ql", function()
			harpoon:list():replace_at(3)
		end, { desc = "Replace file 3" })
		vim.keymap.set("n", "<leader>Q;", function()
			harpoon:list():replace_at(4)
		end, { desc = "Replace file 4" })

		vim.keymap.set("n", "<leader>qx", function()
			harpoon:list():clear()
		end, { desc = "Clear harpoon list" })

		-- Toggle previous & next buffers stored within Harpoon list
		vim.keymap.set("n", "<C-S-P>", function()
			harpoon:list():prev()
		end, { desc = "Go to previous buffer stored in Harpoon list" })
		vim.keymap.set("n", "<C-S-N>", function()
			harpoon:list():next()
		end, { desc = "Go to next buffer stored in Harpoon list" })

		-- basic telescope configuration
		local conf = require("telescope.config").values
		local function toggle_telescope(harpoon_files)
			local file_paths = {}
			for _, item in ipairs(harpoon_files.items) do
				table.insert(file_paths, item.value)
			end

			require("telescope.pickers")
				.new({}, {
					prompt_title = "Harpoon",
					finder = require("telescope.finders").new_table({
						results = file_paths,
					}),
					previewer = conf.file_previewer({}),
					sorter = conf.generic_sorter({}),
				})
				:find()
		end

		vim.keymap.set("n", "<C-e>", function()
			toggle_telescope(harpoon:list())
		end, { desc = "Open Harpoon window" })
	end,
}
