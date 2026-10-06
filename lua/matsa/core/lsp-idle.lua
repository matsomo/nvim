-- Stop all LSP clients after nvim has been unfocused (tmux focus-events) for a
-- while, to free the memory held by idle servers in background tmux windows.
-- On focus they come back via the same autocmd vim.lsp.enable() registers, so
-- typescript-tools, roslyn and mason-enabled servers all re-attach.
local grace_ms = tonumber(vim.env.NVIM_LSP_IDLE_MS) or 10 * 60 * 1000

local timer = assert(vim.uv.new_timer())
local stopped = false
local group = vim.api.nvim_create_augroup("UserLspIdle", {})

vim.api.nvim_create_autocmd("FocusLost", {
	group = group,
	callback = function()
		timer:start(
			grace_ms,
			0,
			vim.schedule_wrap(function()
				for _, client in ipairs(vim.lsp.get_clients()) do
					client:stop()
					stopped = true
				end
			end)
		)
	end,
})

vim.api.nvim_create_autocmd("FocusGained", {
	group = group,
	callback = function()
		timer:stop()
		if not stopped then
			return
		end
		stopped = false
		vim.cmd.doautoall("nvim.lsp.enable FileType")
	end,
})
