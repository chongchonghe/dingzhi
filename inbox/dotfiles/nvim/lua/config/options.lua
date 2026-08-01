-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable line length indicators
vim.opt.colorcolumn = ""
vim.opt.textwidth = 0

-- Disable auto-formatting. You can still manually format code if needed by using the LazyVim keymap <leader>cf (format buffer).
vim.g.autoformat = false

-- HPC Performance Optimizations (only on non-macOS systems)
local is_macos = (vim.uv or vim.loop).os_uname().sysname == "Darwin"

if not is_macos then
	-- Reduce file I/O
	vim.opt.swapfile = false -- Disable swap files (use git instead)
	vim.opt.backup = false -- Disable backup files
	vim.opt.writebackup = false -- Disable backup before overwrite
	vim.opt.undofile = true -- Keep undo history in a file

	-- Reduce update frequency
	vim.opt.updatetime = 1000 -- Slower CursorHold events (default is 250ms)

	-- Limit memory usage
	vim.opt.maxmempattern = 2000 -- Limit pattern matching memory (default 1000)

	-- Reduce syntax complexity for large files
	vim.opt.synmaxcol = 200 -- Only highlight first 200 columns
end

-- disable auto comment continuation
vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = "*",
	callback = function()
		-- use :setlocal semantics
		vim.opt_local.formatoptions:remove({ "r", "o" })
	end,
})

vim.opt.ignorecase = true
vim.opt.smartcase = false
vim.opt.hlsearch = false -- Disable search result highlighting

vim.opt.fillchars:append({ vert = '│' }) -- Use a Unicode box-drawing character
-- OR
vim.opt.fillchars = { vert = '|' }

vim.opt.wrap = true
