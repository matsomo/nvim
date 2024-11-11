-- Close nvim-tree if it's open
vim.api.nvim_exec(
	[[
  autocmd VimEnter * if &modifiable && exists(':NvimTreeClose') | NvimTreeClose | endif
]],
	false
)

-- Open fugitive status page on startup
vim.api.nvim_exec(
	[[
  autocmd VimEnter * if &modifiable && exists(':G') | G | endif
]],
	false
)
