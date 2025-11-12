return {
	"seblyng/roslyn.nvim",
	opts = {
		-- your configuration here
	},
	config = function(_, opts)
		require("roslyn").setup(opts)
	end,
}
