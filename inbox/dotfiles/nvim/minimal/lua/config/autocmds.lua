local is_macos = (vim.uv or vim.loop).os_uname().sysname == "Darwin"

-- Remove distracting keyword/operator highlights in shell scripts (Linux only)
if not is_macos then
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "sh", "bash", "zsh" },
		callback = function()
			vim.cmd([[
        highlight clear shConditional
        highlight clear shOperator
        highlight clear shStatement
        highlight clear shRepeat
      ]])
		end,
	})
end

-- Markdown: wrap, spell, no concealment (keep ``` visible), 2-space indent
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
		vim.opt_local.spell = true
		vim.opt_local.spelllang = "en_us"
		vim.opt_local.conceallevel = 0
		vim.opt_local.shiftwidth = 2
		vim.opt_local.tabstop = 2
	end,
})

-- tex: wrap and spell
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "tex", "bib" },
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.spelllang = "en_us"
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.textwidth = 0
	end,
})

-- Wrap in diff windows
vim.api.nvim_create_augroup("DiffWrap", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "FilterWritePre" }, {
	group = "DiffWrap",
	pattern = "*",
	callback = function()
		if vim.wo.diff then
			vim.cmd("windo setlocal wrap")
		end
	end,
})

-- Visible split separators
vim.api.nvim_create_autocmd("UIEnter", {
	callback = function()
		vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#5fffff", bg = "NONE", bold = true })
	end,
})
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#5fffff", bg = "NONE", bold = true })
	end,
})
