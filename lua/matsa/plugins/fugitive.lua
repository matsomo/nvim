return {
	"tpope/vim-fugitive",
	config = function()
		-- Set the textwidth to 100 before line break for gitcommit files
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "gitcommit",
			command = "setlocal textwidth=100",
		})

		-- Define the GRename function
		function GRename()
			local current_file = vim.fn.expand("%:p")
			local destination = vim.fn.input("Destination: ", current_file)
			local current_buf = vim.fn.bufnr("%")

			-- Move the file
			vim.cmd("G mv " .. current_file .. " " .. destination)

			-- Close the old buffer
			vim.cmd("bdelete! " .. current_buf)

			-- Open the new file in the same window
			vim.cmd("edit " .. destination)
		end

		-- Set the key mapping for GRename
		vim.api.nvim_set_keymap(
			"n",
			"<leader>rf",
			":lua GRename()<CR>",
			{ noremap = true, silent = true, desc = "Rename file" }
		)
	end,
}
