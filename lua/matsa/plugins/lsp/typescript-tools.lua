return {
	"pmizio/typescript-tools.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
	ft = { "typescript", "typescriptreact", "javascript", "javascriptreact", "svelte" },
	config = function()
		require("typescript-tools").setup({
			-- Root one tsserver at the workspace/repo root instead of the default
			-- (nearest tsconfig.json), which in a monorepo spawns a server per
			-- package — forcing a fresh ~10s index every time you enter a new
			-- package and breaking cross-package go-to-definition / imports.
			-- Generic across yarn/pnpm/npm/nx/lerna monorepos and single repos:
			-- prefer a workspace marker, then the lockfile, then .git, then the
			-- nearest package manifest as a last resort.
			root_dir = function(bufnr, on_dir)
				local fname = vim.api.nvim_buf_get_name(bufnr)
				on_dir(vim.fs.root(fname, {
					"pnpm-workspace.yaml",
					"lerna.json",
					"nx.json",
					"turbo.json",
					"yarn.lock",
					"pnpm-lock.yaml",
					"package-lock.json",
					"bun.lockb",
				}) or vim.fs.root(fname, { ".git" }) or vim.fs.root(fname, { "tsconfig.json", "package.json" }))
			end,
			settings = {
				-- MB. Was previously ignored: wrong key (tsserver_max_ts_server_memory)
				-- and not nested under `settings`, so the cap never applied.
				tsserver_max_memory = 4096,
			},
			-- tsserver_path = "tsgo", -- use this when tsgo is ready
		})
		vim.keymap.set(
			"n",
			"<leader>ci",
			"<cmd>TSToolsAddMissingImports<cr>",
			{ desc = "Add all missing imports for file" }
		)
	end,
}
