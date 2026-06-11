local M = {}

-- Header seeded into the buffer on first creation. The export logic in
-- commands.lua strips these lines back out, matching by content rather
-- than line count so that user edits don't break exports.
M.HEADER_LINES = {
	"# Markdown Editor",
	"> Type `/` for commands · `q` to close",
	"",
	"",
}

-- Default configuration
M.config = {
	width = 0.5, -- 50% of editor width
	position = "right", -- 'left', 'right', 'top', 'bottom'
	filetype = "markdown",
	commands = {
		file = true, -- Enable /file command
	},
}

-- State
M.state = {
	buf = nil,
	win = nil,
	is_open = false,
}

-- Setup function
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

-- Compute the split width in columns from config
local function get_split_width()
	local total = vim.o.columns
	local width = M.config.width

	if width > 0 and width <= 1 then
		return math.floor(total * width)
	end
	return width
end

-- Insert text at cursor position
local function insert_at_cursor(text)
	if not M.state.buf or not vim.api.nvim_buf_is_valid(M.state.buf) then
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(M.state.win)
	local row = cursor[1] - 1
	local col = cursor[2]

	local line = vim.api.nvim_buf_get_lines(M.state.buf, row, row + 1, false)[1] or ""
	local new_line = line:sub(1, col) .. text .. line:sub(col + 1)

	vim.api.nvim_buf_set_lines(M.state.buf, row, row + 1, false, { new_line })

	-- Move cursor after inserted text
	vim.api.nvim_win_set_cursor(M.state.win, { row + 1, col + #text })
end

-- Setup autocommands for the buffer
local function setup_buffer_autocmds(buf)
	local group = vim.api.nvim_create_augroup("MarkdownEditorCommands", { clear = false })

	-- Setup completion
	require("markdown-editor.commands").setup_completion(buf)
end

-- Create or get the markdown buffer.
-- Returns (buf, is_new) so callers can place the cursor below the header
-- on the first open without overriding it on subsequent toggles.
local function get_or_create_buffer()
	if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
		return M.state.buf, false
	end

	M.state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(M.state.buf, "filetype", M.config.filetype)
	vim.api.nvim_buf_set_option(M.state.buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, M.HEADER_LINES)

	-- Setup buffer autocmds
	setup_buffer_autocmds(M.state.buf)

	return M.state.buf, true
end

-- Open the markdown editor
function M.open()
	if M.state.is_open then
		return
	end

	local buf, is_new = get_or_create_buffer()
	local width = get_split_width()

	-- Open as a regular vertical split so it integrates with surrounding
	-- buffers (no floating border, inherits Normal background → transparent).
	local mods = M.config.position == "left" and "topleft" or "botright"
	vim.cmd(string.format("%s %dvsplit", mods, width))
	M.state.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(M.state.win, buf)
	M.state.is_open = true

	-- Window-specific options
	vim.api.nvim_win_set_option(M.state.win, "wrap", true)
	vim.api.nvim_win_set_option(M.state.win, "linebreak", true)
	vim.api.nvim_win_set_option(M.state.win, "number", true)
	vim.api.nvim_win_set_option(M.state.win, "relativenumber", false)
	vim.api.nvim_win_set_option(M.state.win, "signcolumn", "no")
	vim.api.nvim_win_set_option(M.state.win, "foldcolumn", "0")
	vim.api.nvim_win_set_option(M.state.win, "winfixwidth", true)

	if is_new then
		vim.api.nvim_win_set_cursor(M.state.win, { #M.HEADER_LINES, 0 })
	end

	-- Setup buffer keymaps
	local opts = { buffer = buf, silent = true }
	vim.keymap.set("n", "q", function()
		M.close()
	end, opts)

	-- Setup completion keybind (Ctrl-Space to trigger completion in insert mode)
	vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", { buffer = buf, silent = true })

	-- Auto-trigger completion when typing /
	vim.keymap.set("i", "/", function()
		vim.api.nvim_feedkeys("/", "n", false)
		vim.schedule(function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true), "n", false)
		end)
	end, { buffer = buf, silent = true })

	-- Setup Enter key to execute completed commands
	vim.keymap.set("i", "<CR>", function()
		require("markdown-editor.commands").check_completion()
		return "<CR>"
	end, { buffer = buf, silent = true, expr = true })
end

-- Close the markdown editor
function M.close()
	if not M.state.is_open then
		return
	end

	if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
		vim.api.nvim_win_close(M.state.win, true)
	end

	M.state.win = nil
	M.state.is_open = false
end

-- Toggle the markdown editor
function M.toggle()
	if M.state.is_open then
		M.close()
	else
		M.open()
	end
end

-- Get current buffer (for commands module)
function M.get_buffer()
	return M.state.buf
end

-- Get current window (for commands module)
function M.get_window()
	return M.state.win
end

-- Insert text (exported for commands module)
function M.insert_text(text)
	insert_at_cursor(text)
end

-- Check if editor is open
function M.is_open()
	return M.state.is_open
end

return M
