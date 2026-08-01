-- Colorscheme configuration with dark/light theme toggle

return {
	-- Uncomment this block if you prefer Catppuccin
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		opts = {
			flavour = "mocha", -- latte, frappe, macchiato, mocha
			transparent_background = false,
			term_colors = true,
			styles = {
				comments = { "italic" },
				conditionals = { "italic" },
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)

			-- Sentinel file: exists = light theme, absent = dark theme (default)
			local sentinel = os.getenv("HOME") .. "/.lighttheme"

			-- Apply persisted theme on startup
			local is_light = vim.loop.fs_stat(sentinel) ~= nil
			vim.g.current_theme_is_dark = not is_light
			if is_light then
				vim.cmd([[colorscheme catppuccin-latte]])
			else
				vim.cmd([[colorscheme catppuccin-mocha]])
			end

			-- Create toggle function
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

			-- Create user command
			vim.api.nvim_create_user_command("ToggleTheme", toggle_theme, {
				desc = "Toggle between dark and light theme",
			})

			-- Create keymap
			vim.keymap.set("n", "<leader>ut", toggle_theme, {
				desc = "Toggle theme (dark/light)",
				noremap = true,
				silent = true,
			})
		end,
	},
}
