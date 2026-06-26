-- Open fugitive status page on startup
-- nested: the status buffer is populated via fugitive's BufReadCmd autocmd,
-- which won't fire from inside another autocmd otherwise
vim.api.nvim_create_autocmd("VimEnter", {
	nested = true,
	callback = function()
		if vim.bo.modifiable and vim.fn.exists(":G") == 2 then
			vim.cmd("G")
		end
	end,
})
