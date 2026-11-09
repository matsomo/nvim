-- Language servers don't start on their own. Coloring comes from tree-sitter,
-- syntax errors from ts-syntax-errors.lua and gd from goto-def.lua, none of
-- which need a server. <leader>cs starts the servers for this nvim (rename,
-- type errors, type-dependent jumps) and attaches them to every open buffer;
-- press it again to stop them. lsp-idle.lua also stops them after the window
-- has been unfocused for a while.
--
-- Every server here (vim.lsp.enable, typescript-tools, roslyn, avalonia) is
-- started through vim.lsp.start, so gating that one function covers them all.
local M = { enabled = false }

-- Ids of clients started through the gate. vim.lsp.get_clients() leaves out
-- clients that are still initializing, so stop() can't rely on it alone.
local started = {}

local orig_start = vim.lsp.start
vim.lsp.start = function(config, opts)
	if not M.enabled then
		return nil
	end
	local id = orig_start(config, opts)
	if id then
		started[id] = true
	end
	return id
end

function M.start()
	M.enabled = true
	-- Re-run the FileType autocmd vim.lsp.enable() registered, for every buffer.
	pcall(vim.cmd.doautoall, "nvim.lsp.enable FileType")
	-- Servers started outside vim.lsp.enable (e.g. avalonia on BufEnter).
	pcall(vim.cmd.doautocmd, "BufEnter")
	vim.notify("Language servers on", vim.log.levels.INFO)
end

function M.stop(quiet)
	local was = M.enabled
	M.enabled = false
	local clients = vim.lsp.get_clients()
	for id in pairs(started) do
		local c = vim.lsp.get_client_by_id(id)
		if c and not vim.list_contains(clients, c) then
			clients[#clients + 1] = c
		end
	end
	started = {}
	-- pcall: typescript-tools' terminate() errors if its tsserver process
	-- hasn't spawned yet (stopping during startup).
	for _, client in ipairs(clients) do
		pcall(client.stop, client)
	end
	-- A server still starting up can ignore the polite shutdown; kill it.
	vim.defer_fn(function()
		for _, client in ipairs(clients) do
			if not client:is_stopped() then
				pcall(client.stop, client, true)
			end
		end
	end, 3000)
	if was and not quiet then
		vim.notify("Language servers off", vim.log.levels.INFO)
	end
end

function M.toggle()
	if M.enabled then
		M.stop()
	else
		M.start()
	end
end

vim.keymap.set("n", "<leader>cs", M.toggle, { desc = "Toggle language servers" })

return M
