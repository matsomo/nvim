return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/lazydev.nvim", ft = "lua", opts = {} },
	},
	config = function()
		-- Never start/reuse an LSP client for buffers that aren't real files.
		-- Neovim's built-in auto-attach only guards by buftype, so plugins that
		-- expose a real filetype in a non-file buffer with an empty buftype
		-- (e.g. diffview's `diffview://...:0:/...` index buffers) slip through.
		-- Servers then resolve a bogus root from the synthetic path and some
		-- reject `initialize` with `file://.` (InvalidParams). Gating at
		-- vim.lsp.start covers both fresh starts and client reuse, and can't be
		-- overridden by a server's own root_dir.
		if not vim.g._lsp_start_file_only then
			vim.g._lsp_start_file_only = true
			local orig_start = vim.lsp.start
			vim.lsp.start = function(config, opts)
				opts = opts or {}
				local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
				local scheme = vim.api.nvim_buf_get_name(bufnr):match("^(%w[%w+.-]*)://")
				if scheme and scheme ~= "file" then
					return nil
				end
				return orig_start(config, opts)
			end
		end

		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				opts.desc = "Show LSP definitions"
				-- Direct LSP jump instead of `Telescope lsp_definitions`: Telescope
				-- waits for every definition-capable client (cssmodules_ls, etc.)
				-- to reply before acting, which is noticeably slow with multiple
				-- clients attached. The direct call jumps as soon as a location is
				-- available. (scrolloff keeps context around the landing line.)
				keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", function()
					vim.diagnostic.jump({ count = -1 })
				end, opts)
				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", function()
					vim.diagnostic.jump({ count = 1 })
				end, opts)
				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)
				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
			end,
		})

		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- disable ts_ls
		vim.lsp.config("ts_ls", {
			autostart = false,
			filetypes = {},
		})

		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					completion = {
						callSnippet = "Replace",
					},
				},
			},
		})

		-- SQL (SQLite). Connections live in ~/.config/sqls/config.yml so the
		-- project's absolute db path stays out of the versioned config.
		-- No SQL formatting on purpose: every SQL formatter explodes SELECT
		-- lists/subqueries and can't preserve a compact hand-aligned layout,
		-- so we disable sqls's formatting capability and keep only completion,
		-- hover and diagnostics.
		vim.lsp.config("sqls", {
			capabilities = capabilities,
			on_attach = function(client, _)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end,
		})

		vim.lsp.config("svelte", {
			capabilities = capabilities,
			on_attach = function(client, bufnr)
				vim.api.nvim_create_autocmd("BufWritePost", {
					pattern = { "*.js", "*.ts" },
					callback = function(ctx)
						-- Restart Svelte server when JS/TS files change
						-- This helps keep Svelte files in sync with component changes
						client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
					end,
				})
			end,
		})
	end,
}
