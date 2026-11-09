-- Stop all LSP clients after nvim has been unfocused (tmux focus-events) for a
-- while, to free the memory held by idle servers in background tmux windows.
-- They stay off until started again with <leader>cs (see lsp-on-demand.lua).
local grace_ms = tonumber(vim.env.NVIM_LSP_IDLE_MS) or 10 * 60 * 1000

local timer = assert(vim.uv.new_timer())
local group = vim.api.nvim_create_augroup("UserLspIdle", {})

vim.api.nvim_create_autocmd("FocusLost", {
	group = group,
	callback = function()
		timer:start(
			grace_ms,
			0,
			vim.schedule_wrap(function()
				require("matsa.core.lsp-on-demand").stop(true)
			end)
		)
	end,
})

vim.api.nvim_create_autocmd("FocusGained", {
	group = group,
	callback = function()
		timer:stop()
	end,
})
