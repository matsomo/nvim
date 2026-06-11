local M = {}

-- Get the markdown editor module
local function get_editor()
	return require("markdown-editor")
end

-- Strip the seeded header from buffer lines if it's still intact.
-- We match by content (not line count) so that if the user has edited
-- or deleted the header, we leave their content untouched.
local function strip_header(lines)
	local editor = get_editor()
	local header = editor.HEADER_LINES or {}
	if #lines < #header then
		return lines
	end
	for i, expected in ipairs(header) do
		if lines[i] ~= expected then
			return lines
		end
	end
	return vim.list_slice(lines, #header + 1)
end

-- Get buffer content suitable for export (header stripped if present).
local function get_export_content()
	local editor = get_editor()
	local buf = editor.get_buffer()
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return ""
	end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	return table.concat(strip_header(lines), "\n")
end

-- Remove a slash-command (e.g. "/export") from the line where it was typed,
-- and reposition the cursor at the gap left behind.
local function remove_command_from_line(row, col_start, col_end)
	local editor = get_editor()
	local buf = editor.get_buffer()
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
	local before = line:sub(1, col_start - 1)
	local after = line:sub(col_end + 1)
	vim.api.nvim_buf_set_lines(buf, row, row + 1, false, { before .. after })
	local win = editor.get_window()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_set_cursor(win, { row + 1, #before })
	end
end

local function export_to_file(content)
	vim.ui.input({
		prompt = "Save to: ",
		default = vim.fn.expand("~/Desktop/export.md"),
		completion = "file",
	}, function(path)
		if not path or path == "" then
			return
		end
		path = vim.fn.expand(path)
		local lines = vim.split(content, "\n", { plain = true })
		local ok, result = pcall(vim.fn.writefile, lines, path)
		if ok and result == 0 then
			vim.notify("Exported to " .. path, vim.log.levels.INFO)
		else
			vim.notify("Export failed: " .. tostring(result), vim.log.levels.ERROR)
		end
	end)
end

local function export_to_clipboard(content)
	if vim.fn.has("clipboard") == 0 then
		vim.notify("No clipboard support in this Neovim build", vim.log.levels.ERROR)
		return
	end
	vim.fn.setreg("+", content)
	vim.notify("Copied to clipboard", vim.log.levels.INFO)
end

-- Execute the /clear command: reset buffer to just the header.
local function execute_clear_command(_line_text, row, col_start, col_end)
	local editor = get_editor()
	local buf = editor.get_buffer()
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	-- Remove the typed `/clear` first so it isn't visible during the reset.
	remove_command_from_line(row, col_start, col_end)

	local header = editor.HEADER_LINES or {}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)

	local win = editor.get_window()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_set_cursor(win, { #header, 0 })
	end

	-- Drop back to normal mode so the user isn't stuck in insert on an
	-- empty line they didn't expect.
	if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
		vim.cmd("stopinsert")
	end
end

-- Execute the /export command: prompt for destination, then export.
local function execute_export_command(_line_text, row, col_start, col_end)
	remove_command_from_line(row, col_start, col_end)

	vim.ui.select({ "Markdown file", "Clipboard" }, {
		prompt = "Export as:",
	}, function(choice)
		if not choice then
			return
		end
		local content = get_export_content()
		if choice == "Markdown file" then
			export_to_file(content)
		elseif choice == "Clipboard" then
			export_to_clipboard(content)
		end
	end)
end

-- Get git root directory
local function get_git_root()
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if vim.v.shell_error == 0 then
		return git_root
	end
	return nil
end

-- Convert absolute path to relative path from git root
local function make_relative_path(absolute_path)
	local git_root = get_git_root()
	if not git_root then
		return absolute_path
	end

	-- Normalize paths
	git_root = vim.fn.fnamemodify(git_root, ":p"):gsub("/$", "")
	absolute_path = vim.fn.fnamemodify(absolute_path, ":p"):gsub("/$", "")

	-- Check if the path starts with git root
	if absolute_path:sub(1, #git_root) == git_root then
		local relative = absolute_path:sub(#git_root + 2) -- +2 to skip the leading slash
		return relative
	end

	return absolute_path
end

-- Execute the /file command
local function execute_file_command(line_text, row, col_start, col_end)
	local editor = get_editor()

	-- Open telescope file picker
	require("telescope.builtin").find_files({
		prompt_title = "Insert File Path",
		attach_mappings = function(prompt_bufnr, map)
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")

			-- Override the default select action
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)

				if selection then
					local absolute_path = selection.path or selection.value
					local file_path = make_relative_path(absolute_path)
					local buf = editor.get_buffer()

					if buf and vim.api.nvim_buf_is_valid(buf) then
						-- Get the current line
						local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""

						-- Replace /file with the selected file path
						local before = line:sub(1, col_start - 1)
						local after = line:sub(col_end + 1)
						local new_line = before .. file_path .. after

						vim.api.nvim_buf_set_lines(buf, row, row + 1, false, { new_line })

						-- Set cursor position after the inserted path
						local new_col = col_start - 1 + #file_path
						local win = editor.get_window()
						if win and vim.api.nvim_win_is_valid(win) then
							vim.api.nvim_win_set_cursor(win, { row + 1, new_col })
						end
					end
				end
			end)

			return true
		end,
	})
end

-- Setup completion for commands
function M.setup_completion(buf)
	-- Set up omnifunc completion
	vim.api.nvim_buf_set_option(buf, "omnifunc", "v:lua.require'markdown-editor.commands'.complete")
end

-- Completion function
function M.complete(findstart, base)
	local editor = get_editor()
	local buf = editor.get_buffer()
	local win = editor.get_window()

	if not buf or not win then
		return findstart == 1 and -1 or {}
	end

	if findstart == 1 then
		-- Find the start of the command
		local cursor = vim.api.nvim_win_get_cursor(win)
		local line = vim.api.nvim_get_current_line()
		local col = cursor[2]

		-- Find the start of a potential command (look for /)
		local start = col
		while start > 0 and line:sub(start, start) ~= " " and line:sub(start, start) ~= "\t" do
			start = start - 1
		end

		-- Check if we found a /
		if line:sub(start + 1, start + 1) == "/" then
			return start
		end

		return -3 -- Cancel silently
	else
		-- Return completion items
		if base:match("^/") then
			return {
				{
					word = "/file",
					menu = "Insert file path",
					kind = "command",
					info = "Opens Telescope to select a file and insert its path",
				},
				{
					word = "/export",
					menu = "Export buffer",
					kind = "command",
					info = "Export buffer contents to a markdown file or the clipboard",
				},
				{
					word = "/clear",
					menu = "Clear buffer",
					kind = "command",
					info = "Reset the buffer, keeping only the header",
				},
			}
		end
		return {}
	end
end

-- Trigger command action (called when selecting a completion)
function M.execute_completion(item)
	local editor = get_editor()
	local buf = editor.get_buffer()
	local win = editor.get_window()

	if not buf or not win then
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(win)
	local row = cursor[1] - 1
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""

	-- Find where /file is in the line
	local cmd_start, cmd_end = line:find("/file")

	if cmd_start and item == "/file" then
		vim.schedule(function()
			execute_file_command(line, row, cmd_start - 1, cmd_end)
		end)
	end
end

-- Check if user completed a command and execute it
function M.check_completion()
	local editor = get_editor()
	local buf = editor.get_buffer()
	local win = editor.get_window()

	if not buf or not win then
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(win)
	local row = cursor[1] - 1
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""

	-- Check if the line ends with a command that was just completed
	local before_cursor = line:sub(1, cursor[2])

	-- Check for /file command that was just typed
	if before_cursor:match("/file$") then
		vim.schedule(function()
			local cmd_start = before_cursor:len() - 4 -- length of "file"
			execute_file_command(line, row, cmd_start, cursor[2])
		end)
	elseif before_cursor:match("/export$") then
		vim.schedule(function()
			local cmd_start = before_cursor:len() - 6 -- length of "export"
			execute_export_command(line, row, cmd_start, cursor[2])
		end)
	elseif before_cursor:match("/clear$") then
		vim.schedule(function()
			local cmd_start = before_cursor:len() - 5 -- length of "clear"
			execute_clear_command(line, row, cmd_start, cursor[2])
		end)
	end
end

-- Manually trigger /file command (can be mapped to a key)
function M.trigger_file_picker()
	local editor = get_editor()

	if not editor.is_open() then
		vim.notify("Markdown editor is not open", vim.log.levels.WARN)
		return
	end

	local buf = editor.get_buffer()
	local win = editor.get_window()

	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(win)
	local row = cursor[1] - 1

	execute_file_command("", row, cursor[2], cursor[2])
end

return M
