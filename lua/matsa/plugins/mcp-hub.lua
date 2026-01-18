return {
	"ravitemer/mcphub.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},

	build = "npm install -g mcp-hub@latest", -- Installs `mcp-hub` node binary globally everytime the plugin is updated
	config = function()
		require("mcphub").setup({
			--- default port: http://localhost:37373/

			--- workspaces allows for specific configurations on project level
			-- workspace = {
			-- 	enabled = true, -- Default: true
			-- 	look_for = { ".mcphub/servers.json" },
			-- 	reload_on_dir_changed = true, -- Auto-switch on directory change
			-- 	port_range = { min = 40000, max = 41000 }, -- Port range for workspace hubs
			-- 	get_port = nil, -- Optional function for custom port assignment
			-- },
			vim.keymap.set("n", "<leader>mh", "<cmd>MCPHub<cr>", { desc = "Toggle MCP Hub view" }),
		})
	end,
}
