return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/mcphub.nvim",
	},
	event = "VeryLazy",
	keys = {
		{
			"<leader>cc",
			"<cmd>CodeCompanionChat Toggle<cr>",
			desc = "CodeCompanion - Toggle chat",
			mode = { "n", "v" },
		},
	},
	config = function()
		require("codecompanion").setup({
			log_level = "DEBUG",
			display = {
				chat = {
					show_token_count = true,
				},
			},
			interactions = {
				chat = {
					adapter = {
						name = "claude_code",
						model = "opus",
						sources = {
							buffer = {
								type = "buffers",
							},
						},
					},
					slash_commands = {
						image = {
							opts = {
								dirs = {
									os.getenv("HOME") .. "/Desktop",
									-- Add other directories you want to search:
									-- os.getenv("HOME") .. "/Downloads",
									-- os.getenv("HOME") .. "/Pictures",
								},
							},
						},
					},
				},
			},
			extensions = {
				mcphub = {
					callback = "mcphub.extensions.codecompanion",
					opts = {
						-- MCP Tools
						make_tools = true, -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
						show_server_tools_in_chat = true, -- Show individual tools in chat completion (when make_tools=true)
						add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
						show_result_in_chat = true, -- Show tool results directly in chat buffer
						format_tool = nil, -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer
						-- MCP Resources
						make_vars = true, -- Convert MCP resources to #variables for prompts
						-- MCP Prompts
						make_slash_commands = true, -- Add MCP prompts as /slash commands
					},
				},
			},
			adapters = {
				claude_code = function()
					return require("codecompanion.adapters").extend("claude_code", {
						env = {
							CLAUDE_CODE_OAUTH_TOKEN = os.getenv("CLAUDE_CODE_OAUTH_TOKEN"),
						},
					})
				end,
			},
		})
	end,
}
