-- Essential editor options (previously provided by LazyVim defaults)
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 4
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.clipboard = "unnamedplus"
vim.opt.timeoutlen = 300
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

-- From current config
vim.opt.colorcolumn = ""
vim.opt.textwidth = 0
vim.opt.ignorecase = true
vim.opt.smartcase = false
vim.opt.hlsearch = false
vim.opt.fillchars = { vert = "|" }
vim.opt.wrap = true

-- HPC performance optimizations (Linux/remote only)
local is_macos = (vim.uv or vim.loop).os_uname().sysname == "Darwin"

if not is_macos then
	vim.opt.swapfile = false
	vim.opt.backup = false
	vim.opt.writebackup = false
	vim.opt.undofile = true
	vim.opt.updatetime = 1000
	vim.opt.maxmempattern = 2000
	vim.opt.synmaxcol = 200
end

-- Disable auto comment continuation
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "r", "o" })
	end,
})
