return {
	"mason-org/mason.nvim",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "Mason", "MasonInstall", "MasonUpdate" },
	dependencies = {
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
			registries = {
				"github:mason-org/mason-registry",
				"github:Crashdummyy/mason-registry",
			},
		})

		mason_lspconfig.setup({
			-- Don't auto-enable installed tools that aren't our chosen LSP:
			-- oxlint/stylua are already run via nvim-lint/conform, and
			-- omnisharp/csharp_ls/roslyn_ls all duplicate roslyn.nvim for C#.
			-- (roslyn_ls maps to the roslyn-language-server package we install,
			-- so mason-lspconfig would otherwise attach a second C# client.)
			automatic_enable = {
				exclude = { "oxlint", "stylua", "omnisharp", "csharp_ls", "roslyn_ls" },
			},
			-- list of servers for mason to install
			ensure_installed = {
				-- "ts_query_ls",
				-- "ts_ls",
				"html",
				"cssls",
				"cssmodules_ls",
				"jsonls",
				"lua_ls",
				"gopls",
				"svelte",
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"oxlint",
				"stylua", -- lua formatter
				"typescript-language-server", -- required for typescript-tools
				"csharpier", -- C# formatter
				-- Roslyn LSP server that roslyn.nvim drives (from the
				-- Crashdummyy registry). Without it no client attaches to
				-- .cs buffers, so hover/K silently falls back to `man`.
				"roslyn-language-server",
			},
		})
	end,
}
