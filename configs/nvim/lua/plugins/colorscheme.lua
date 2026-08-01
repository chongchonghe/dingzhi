-- Colorscheme. dingzhi is Catppuccin Mocha, dark only.
--
-- The original config carried a light/dark toggle driven by a sentinel file in
-- $HOME. It is deliberately not ported: switching themes live across
-- nested TUIs (kitty -> tmux -> nvim -> lazygit -> vifm) never worked
-- reliably, and every layer had to be taught the same convention.

return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		opts = {
			flavour = "mocha",
			transparent_background = false,
			term_colors = true,
			styles = {
				comments = { "italic" },
				conditionals = { "italic" },
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd([[colorscheme catppuccin-mocha]])
		end,
	},
}
