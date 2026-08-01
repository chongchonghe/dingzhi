return {
	-- Treesitter: markdown parsers only (required by render-markdown)
	-- pcall silences first-install failure; parsers are installed via :TSUpdate build regardless
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		ft = { "markdown" },
		config = function()
			local ok, configs = pcall(require, "nvim-treesitter.configs")
			if not ok then return end
			configs.setup({
				ensure_installed = { "markdown", "markdown_inline" },
				highlight = { enable = false },
				indent = { enable = false },
			})
		end,
	},

	-- Markdown rendering: code block backgrounds, tables, checkboxes (no bullets, no heading decoration)
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {
			render_modes = { "n", "i", "c", "t" },
			max_file_size = 999.0,

			heading = { enabled = false },

			code = {
				enabled = true,
				sign = false,
				style = "normal",
				left_pad = 1,
				right_pad = 1,
				width = "block",
				border = "none",
			},

			bullet = { enabled = false },

			checkbox = {
				enabled = true,
				unchecked = { icon = "☐ " },
				checked = { icon = "☑ " },
				custom = {
					todo = { raw = "[-]", rendered = "◐ ", highlight = "RenderMarkdownTodo" },
				},
			},

			quote = {
				enabled = true,
				icon = "▎",
				repeat_linebreak = true,
			},

			pipe_table = {
				enabled = true,
				preset = "round",
				style = "full",
				cell = "padded",
				border = { "┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "│", "─" },
				alignment_indicator = "━",
				head = "RenderMarkdownTableHead",
				row = "RenderMarkdownTableRow",
			},
		},
	},

	-- Marp slide preview
	{
		"mpas/marp-nvim",
		config = function()
			require("marp").setup({
				port = 8080,
				wait_for_response_timeout = 30,
				wait_for_response_delay = 1,
			})
		end,
	},

	-- Snippets (loads luasnippets/ directory)
	{
		"L3MON4D3/LuaSnip",
		config = function()
			require("luasnip.loaders.from_lua").load({
				paths = { vim.fn.stdpath("config") .. "/luasnippets" },
			})
		end,
	},
}
