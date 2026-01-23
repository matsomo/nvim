return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")
		-- local lazy_status = require("lazy.status") -- to configure lazy pending updates count

		local colors = {
			blue = "#65D1FF",
			green = "#3EFFDC",
			violet = "#FF61EF",
			yellow = "#FFDA7B",
			red = "#FF4A4A",
			fg = "#c3ccdc",
			bg = "#112638",
			inactive_bg = "#2c3043",
		}

		local my_lualine_theme = {
			normal = {
				a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			insert = {
				a = { bg = colors.green, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			visual = {
				a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			command = {
				a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			replace = {
				a = { bg = colors.red, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			inactive = {
				a = { bg = colors.inactive_bg, fg = colors.semilightgray, gui = "bold" },
				b = { bg = colors.inactive_bg, fg = colors.semilightgray },
				c = { bg = colors.inactive_bg, fg = colors.semilightgray },
			},
		}

		-- configure lualine with modified theme
		lualine.setup({
			options = {
				theme = my_lualine_theme,
			},
			sections = {
				lualine_c = { { "filename", path = 1 } },
				lualine_x = {
					{
						function()
							-- Check if MCPHub is loaded
							if not vim.g.loaded_mcphub then
								return "MCPHub loaded"
							end

							local count = vim.g.mcphub_servers_count or 0
							local status = vim.g.mcphub_status or "stopped"
							local executing = vim.g.mcphub_executing

							-- Show "-" when stopped
							if status == "stopped" then
								return "MCPHub stopped"
							end

							-- Show spinner when executing, starting, or restarting
							if executing or status == "starting" or status == "restarting" then
								local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
								local frame = math.floor(vim.loop.now() / 100) % #frames + 1
								return "MCPHub " .. frames[frame]
							end

							return "MCP servers: " .. count
						end,
						color = function()
							if not vim.g.loaded_mcphub then
								return { fg = colors.inactive_bg } -- Gray for not loaded
							end

							local status = vim.g.mcphub_status or "stopped"
							if status == "ready" or status == "restarted" then
								return { fg = colors.green } -- Green for connected
							elseif status == "starting" or status == "restarting" then
								return { fg = colors.yellow } -- Orange for connecting
							else
								return { fg = colors.red } -- Red for error/stopped
							end
						end,
					},
				},

				-- lualine_x = {
				-- 	{
				-- 		lazy_status.updates,
				-- 		cond = lazy_status.has_updates,
				-- 		color = { fg = "#ff9e64" },
				-- 	},
				-- 	{ "encoding" },
				-- 	{ "fileformat" },
				-- 	{ "filetype" },
				-- },
			},
		})
	end,
}
