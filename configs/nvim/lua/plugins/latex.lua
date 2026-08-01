-- LaTeX editing support
local is_macos = (vim.uv or vim.loop).os_uname().sysname == "Darwin"

-- tex-specific options and spell checking
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

return {
	-- vimtex: compilation, syntax, navigation, ToC, SyncTeX
	{
		"lervag/vimtex",
		lazy = false, -- must load at startup for filetype hooks
		init = function()
			vim.g.vimtex_compiler_method = "latexmk"

			-- PDF viewer: Skim on macOS (with SyncTeX), zathura on Linux
			if is_macos then
				vim.g.vimtex_view_method = "skim"
				vim.g.vimtex_view_skim_sync = 1
				vim.g.vimtex_view_skim_activate = 1
			else
				vim.g.vimtex_view_method = "zathura"
			end

			-- Disable vimtex's own completion (blink.cmp + texlab handles it)
			vim.g.vimtex_complete_enabled = 0

			-- Open quickfix on errors but don't steal focus
			vim.g.vimtex_quickfix_mode = 2

			-- Disable slow folding
			vim.g.vimtex_fold_enabled = 0
		end,
	},

	-- texlab LSP: \cite{}, \ref{}, diagnostics, go-to-definition (macOS only)
	-- nvim-lspconfig is already guarded to is_macos in ui.lua
	{
		"neovim/nvim-lspconfig",
		optional = true,
		opts = {
			servers = {
				texlab = {},
			},
		},
	},

	-- Add spell source alongside normal sources for tex files
	{
		"saghen/blink.cmp",
		opts = {
			sources = {
				per_filetype = {
					tex = { "lsp", "snippets", "path", "buffer", "spell" },
				},
			},
		},
	},
}
