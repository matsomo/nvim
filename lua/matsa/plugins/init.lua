return {
  "nvim-lua/plenary.nvim", -- lua functions used by many plugins
  "christoomey/vim-tmux-navigator", -- tmux & split window navigation
  {
    "daliusd/incr.nvim",
    opts = {
      incr_key = "<leader>e",
      decr_key = "<bs>",
    },
  },
}
