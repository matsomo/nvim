-- vim.g.netrw_liststyle = 3
vim.opt.relativenumber = true
vim.opt.number = true

-- tabs & indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.scrolloff = 8

vim.opt.wrap = false

-- disable swap and backup files
vim.opt.swapfile = false
vim.opt.backup = false

-- folding
vim.opt.foldmethod = "manual"

-- search settings
vim.opt.ignorecase = true -- ignore case when searching
vim.opt.smartcase = true -- assume case-sensitive if search includes mixed case

vim.opt.cursorline = true

-- theme
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.signcolumn = "yes"

-- backspace
vim.opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
vim.opt.clipboard = "unnamedplus" -- use system clipboard
-- don't override yank with paste
vim.api.nvim_set_keymap("n", "p", "P", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "p", "P", { noremap = true, silent = true })

-- split windows
vim.opt.splitright = true -- split vertical window to the right
vim.opt.splitbelow = true -- split horizontal window to the bottom

-- local session options
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- cursor
vim.opt.virtualedit = "onemore" -- allow cursor to move past the last character
vim.opt.guicursor =
	"n:block-NormalCursor,v-c:block-NormalCursor,i-ci:block-DimmedCursor,r-cr-o:block-DimmedCursor,sm:block-NormalCursor"
vim.cmd([[
  highlight NormalCursor guifg=black guibg=white
  highlight DimmedCursor guifg=black guibg=#6ab5f6
]])
