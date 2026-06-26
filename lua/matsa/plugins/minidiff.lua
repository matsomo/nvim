return {
	"echasnovski/mini.diff",
	-- loaded on demand as a codecompanion dependency (inline diff provider)
	lazy = true,
	config = function()
		local diff = require("mini.diff")
		diff.setup({
			-- Disabled by default
			source = diff.gen_source.none(),
		})
	end,
}
