return {
	"seblyng/roslyn.nvim",
	ft = "cs",
	opts = {
		-- your configuration here
	},
	config = function(_, opts)
		require("roslyn").setup(opts)
	end,
}
