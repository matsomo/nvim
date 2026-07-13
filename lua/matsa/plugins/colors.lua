-- Theme setup: dark = TokyoNight (custom navy palette), light = GitHub Light
-- High Contrast (maximum legibility, synced with ghostty + tmux).
-- Toggle with <leader>tt / :ThemeToggle. The choice persists across restarts.

local state_file = vim.fn.stdpath("data") .. "/theme-bg.txt"

local function read_saved_bg()
	local f = io.open(state_file, "r")
	if not f then
		return nil
	end
	local content = f:read("*l")
	f:close()
	if content == "light" or content == "dark" then
		return content
	end
	return nil
end

local function save_bg(bg)
	local f = io.open(state_file, "w")
	if f then
		f:write(bg)
		f:close()
	end
end

local function apply_theme(bg)
	vim.o.background = bg
	if bg == "light" then
		vim.cmd([[colorscheme github_light_high_contrast]])
	else
		vim.cmd([[colorscheme tokyonight]])
	end
	save_bg(bg)
end

local function toggle_theme()
	apply_theme(vim.o.background == "dark" and "light" or "dark")
end

return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local dark = {
				bg = "#011628",
				bg_dark = "#011423",
				bg_highlight = "#143652",
				bg_search = "#0A64AC",
				bg_visual = "#275378",
				fg = "#CBE0F0",
				fg_dark = "#B4D0E9",
				fg_gutter = "#627E97",
				border = "#547998",
				comment = "#7b97b0",
				unused = "#6f889e",
			}

			require("tokyonight").setup({
				style = "night",
				transparent = false,
				cache = false, -- always recompile so palette edits take effect immediately
				on_colors = function(colors)
					colors.bg = dark.bg
					colors.bg_dark = dark.bg_dark
					colors.bg_float = dark.bg_dark
					colors.bg_highlight = dark.bg_highlight
					colors.bg_popup = dark.bg_dark
					colors.bg_search = dark.bg_search
					colors.bg_sidebar = dark.bg_dark
					colors.bg_statusline = dark.bg_dark
					colors.bg_visual = dark.bg_visual
					colors.border = dark.border
					colors.fg = dark.fg
					colors.fg_dark = dark.fg_dark
					colors.fg_float = dark.fg
					colors.fg_gutter = dark.fg_gutter
					colors.fg_sidebar = dark.fg_dark
				end,
				on_highlights = function(highlights)
					highlights.Comment = { fg = dark.comment, italic = true }
					highlights.UnusedVariable = { fg = dark.unused, underline = false }
					highlights.UnusedImport = { fg = dark.unused, underline = false }
					highlights.LspDiagnosticsUnused = { fg = dark.unused, underline = false }
					highlights.LspDiagnosticsUnusedVariable = { fg = dark.unused, underline = false }
					highlights.LspDiagnosticsUnusedImport = { fg = dark.unused, underline = false }
					highlights.DiagnosticUnnecessary = { fg = dark.unused, underline = false }
					highlights.DiagnosticUnused = { fg = dark.unused, underline = false }
					highlights.DiagnosticUnusedVariable = { fg = dark.unused, underline = false }
					highlights.DiagnosticUnusedImport = { fg = dark.unused, underline = false }
				end,
			})
		end,
	},
	{
		"projekt0n/github-nvim-theme",
		lazy = false,
		priority = 1000,
		dependencies = { "folke/tokyonight.nvim" },
		config = function()
			require("github-theme").setup({
				options = {
					styles = { comments = "italic" },
				},
				groups = {
					github_light_high_contrast = {
						-- match the dark theme's preference: dim unused, no underline
						DiagnosticUnnecessary = { fg = "#66707b", style = "NONE" },
					},
				},
			})

			vim.api.nvim_create_user_command("ThemeToggle", toggle_theme, {
				desc = "Toggle light/dark theme",
			})
			vim.keymap.set("n", "<leader>tt", toggle_theme, { desc = "Toggle light/dark theme" })

			-- restore the last-used theme (defaults to dark)
			apply_theme(read_saved_bg() or "dark")
		end,
	},
}
