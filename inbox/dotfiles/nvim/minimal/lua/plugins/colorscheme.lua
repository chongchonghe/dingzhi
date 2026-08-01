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

			local sentinel = os.getenv("HOME") .. "/.lighttheme"
			local is_light = vim.loop.fs_stat(sentinel) ~= nil
			vim.g.current_theme_is_dark = not is_light
			if is_light then
				vim.cmd([[colorscheme catppuccin-latte]])
			else
				vim.cmd([[colorscheme catppuccin-mocha]])
			end

			local function toggle_theme()
				if vim.g.current_theme_is_dark then
					vim.cmd([[colorscheme catppuccin-latte]])
					vim.g.current_theme_is_dark = false
					io.open(sentinel, "w"):close()
					vim.notify("Switched to light theme", vim.log.levels.INFO)
				else
					vim.cmd([[colorscheme catppuccin-mocha]])
					vim.g.current_theme_is_dark = true
					os.remove(sentinel)
					vim.notify("Switched to dark theme", vim.log.levels.INFO)
				end
			end

			vim.api.nvim_create_user_command("ToggleTheme", toggle_theme, {
				desc = "Toggle between dark and light theme",
			})
			vim.keymap.set("n", "<leader>ut", toggle_theme, {
				desc = "Toggle theme (dark/light)",
				noremap = true,
				silent = true,
			})
		end,
	},
}
