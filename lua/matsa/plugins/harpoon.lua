return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
	keys = {
		{
			"<leader>a",
			function()
				require("harpoon"):list():add()
			end,
			desc = "Add file to list",
		},
		{
			"<leader>qj",
			function()
				require("harpoon"):list():select(1)
			end,
			desc = "Go to file 1",
		},
		{
			"<leader>qk",
			function()
				require("harpoon"):list():select(2)
			end,
			desc = "Go to file 2",
		},
		{
			"<leader>ql",
			function()
				require("harpoon"):list():select(3)
			end,
			desc = "Go to file 3",
		},
		{
			"<leader>q;",
			function()
				require("harpoon"):list():select(4)
			end,
			desc = "Go to file 4",
		},
		{
			"<leader>Qj",
			function()
				require("harpoon"):list():replace_at(1)
			end,
			desc = "Replace file 1",
		},
		{
			"<leader>Qk",
			function()
				require("harpoon"):list():replace_at(2)
			end,
			desc = "Replace file 2",
		},
		{
			"<leader>Ql",
			function()
				require("harpoon"):list():replace_at(3)
			end,
			desc = "Replace file 3",
		},
		{
			"<leader>Q;",
			function()
				require("harpoon"):list():replace_at(4)
			end,
			desc = "Replace file 4",
		},
		{
			"<leader>qx",
			function()
				require("harpoon"):list():clear()
			end,
			desc = "Clear harpoon list",
		},
		{
			"<C-S-P>",
			function()
				require("harpoon"):list():prev()
			end,
			desc = "Go to previous buffer stored in Harpoon list",
		},
		{
			"<C-S-N>",
			function()
				require("harpoon"):list():next()
			end,
			desc = "Go to next buffer stored in Harpoon list",
		},
		{
			"<C-e>",
			function()
				local harpoon = require("harpoon")
				local conf = require("telescope.config").values
				local file_paths = {}
				for _, item in ipairs(harpoon:list().items) do
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
			end,
			desc = "Open Harpoon window",
		},
	},
	config = function()
		require("harpoon"):setup()
	end,
}
