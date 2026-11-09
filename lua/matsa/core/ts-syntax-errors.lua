-- Syntax errors from tree-sitter, shown as diagnostics, so a buffer reports
-- broken syntax without a language server. Tree-sitter already parses every
-- buffer for highlighting; this only reads the ERROR / MISSING nodes it
-- produced. When a language server is attached it reports these itself, so
-- these diagnostics step aside.
local api = vim.api
local ns = api.nvim_create_namespace("ts_syntax_errors")

local FILETYPES = {
	bash = true,
	cs = true,
	css = true,
	go = true,
	javascript = true,
	javascriptreact = true,
	json = true,
	lua = true,
	sh = true,
	svelte = true,
	typescript = true,
	typescriptreact = true,
	yaml = true,
}
local MAX = 30

local function snippet(node, buf)
	local s = vim.treesitter.get_node_text(node, buf):match("^%s*([^\n]*)") or ""
	s = vim.trim(s)
	if #s > 30 then
		s = s:sub(1, 30) .. "…"
	end
	return s
end

local function collect(node, buf, out)
	for child in node:iter_children() do
		if #out >= MAX then
			return
		end
		if child:missing() then
			local t = child:type()
			local sr, sc = child:start()
			out[#out + 1] = {
				lnum = sr,
				col = sc,
				message = child:named() and ("Missing %s"):format(t:gsub("_", " ")) or ("Missing `%s`"):format(t),
			}
		elseif child:type() == "ERROR" then
			local sr, sc, er, ec = child:range()
			if er > sr then
				-- underline only the first line of a multi-line error
				er, ec = sr, #(api.nvim_buf_get_lines(buf, sr, sr + 1, false)[1] or "")
			end
			local s = snippet(child, buf)
			out[#out + 1] = {
				lnum = sr,
				col = sc,
				end_lnum = er,
				end_col = ec,
				message = s ~= "" and ("Syntax error at `%s`"):format(s) or "Syntax error",
			}
		elseif child:has_error() then
			collect(child, buf, out)
		end
	end
end

local function check(buf)
	if not api.nvim_buf_is_valid(buf) or not api.nvim_buf_is_loaded(buf) then
		return
	end
	if not FILETYPES[vim.bo[buf].filetype] or #vim.lsp.get_clients({ bufnr = buf }) > 0 then
		vim.diagnostic.reset(ns, buf)
		return
	end
	local ok, parser = pcall(vim.treesitter.get_parser, buf, nil, { error = false })
	if not ok or not parser then
		return
	end
	local tree = parser:parse()[1]
	local out = {}
	if tree and tree:root():has_error() then
		collect(tree:root(), buf, out)
	end
	for _, d in ipairs(out) do
		d.severity = vim.diagnostic.severity.ERROR
		d.source = "treesitter"
	end
	vim.diagnostic.set(ns, buf, out)
end

local timers = {}
local function schedule(buf, delay)
	local t = timers[buf]
	if not t then
		t = assert(vim.uv.new_timer())
		timers[buf] = t
	end
	t:stop()
	t:start(delay, 0, vim.schedule_wrap(function()
		check(buf)
	end))
end

local group = api.nvim_create_augroup("UserTsSyntaxErrors", {})

api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave", "TextChanged" }, {
	group = group,
	callback = function(ev)
		-- not while typing: half-written code is always broken
		if api.nvim_get_mode().mode:sub(1, 1) ~= "i" then
			schedule(ev.buf, 150)
		end
	end,
})

api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
	group = group,
	callback = function(ev)
		-- LspDetach fires before the client is gone from the buffer
		schedule(ev.buf, 100)
	end,
})

api.nvim_create_autocmd("BufWipeout", {
	group = group,
	callback = function(ev)
		local t = timers[ev.buf]
		if t then
			t:stop()
			t:close()
			timers[ev.buf] = nil
		end
	end,
})
