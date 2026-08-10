-- Open fugitive status page on startup
-- nested: the status buffer is populated via fugitive's BufReadCmd autocmd,
-- which won't fire from inside another autocmd otherwise
vim.api.nvim_create_autocmd("VimEnter", {
	nested = true,
	callback = function()
		if not (vim.bo.modifiable and vim.fn.exists(":G") == 2) then
			return
		end

		-- Detect a "landing" startup buffer: bare `nvim`, or `nvim <dir>` where
		-- oil hijacks netrw and shows the directory listing. In those cases we
		-- want fugitive to be the sole landing window, not an oil/empty split.
		local name = vim.api.nvim_buf_get_name(0)
		local is_landing = name == ""
			or vim.bo.filetype == "oil"
			or name:match("^oil://") ~= nil
			or vim.fn.isdirectory(name) == 1

		-- Inside a Git repo, land on fugitive's status page. Outside one, land on
		-- oil at the current root (`:G` errors outside a repo anyway).
		if vim.fn.FugitiveGitDir() ~= "" then
			local landing_buf = vim.api.nvim_get_current_buf()
			vim.cmd("G")
			if is_landing then
				vim.cmd("only")
				-- Wipe the hidden landing buffer. Oil populates it asynchronously,
				-- and once :only closes its window, oil's callback finishes in
				-- whatever window is current instead - replaying BufReadPost for
				-- the oil:// URL in the fugitive status buffer, which stomps its
				-- filetype and wipes the highlighting.
				if landing_buf ~= vim.api.nvim_get_current_buf() and vim.api.nvim_buf_is_valid(landing_buf) then
					pcall(vim.api.nvim_buf_delete, landing_buf, { force = true })
				end
			end
		elseif is_landing then
			-- `nvim <dir>` already hijacks into an oil buffer; only open oil
			-- ourselves for a bare/empty landing buffer.
			if vim.bo.filetype ~= "oil" then
				require("oil").open(vim.fn.getcwd())
			end
			vim.cmd("only")
		end
	end,
})
