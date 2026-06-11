return {
	dir = vim.fn.stdpath("config") .. "/lua/custom-plugins/markdown-editor",
	name = "markdown-editor",
	dependencies = {
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		local markdown_editor = require("markdown-editor")

		-- Setup the plugin
		markdown_editor.setup({
			width = 0.5, -- 50% of editor width
			position = "right", -- 'left', 'right'
			filetype = "markdown",
		})

		-- Create user commands
		vim.api.nvim_create_user_command("MarkdownEditorToggle", function()
			markdown_editor.toggle()
		end, { desc = "Toggle markdown editor split" })

		vim.api.nvim_create_user_command("MarkdownEditorOpen", function()
			markdown_editor.open()
		end, { desc = "Open markdown editor split" })

		vim.api.nvim_create_user_command("MarkdownEditorClose", function()
			markdown_editor.close()
		end, { desc = "Close markdown editor split" })

		-- Keymaps
		vim.keymap.set("n", "<leader>me", function()
			markdown_editor.toggle()
		end, { desc = "Toggle Markdown Editor", silent = true })

		-- Optional: Keymap to manually trigger file picker
		vim.keymap.set("n", "<leader>mf", function()
			if markdown_editor.is_open() then
				require("markdown-editor.commands").trigger_file_picker()
			end
		end, { desc = "Insert file path (Markdown Editor)", silent = true })
	end,
}
