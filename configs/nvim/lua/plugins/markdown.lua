-- Markdown rendering, note-taking, and Obsidian configuration

-- Enable spell checking for markdown
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.spelllang = "en_us"
	end,
})

-- Cut a markdown slide: content between two '---' separators (includes first ---, excludes second ---)
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(ev)
		vim.keymap.set("n", "<leader>xs", function()
			local buf = ev.buf
			local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
			local total = vim.api.nvim_buf_line_count(buf)

			-- Search backward for ^---$ (inclusive of current line)
			local start_line = nil
			for i = cursor_line, 1, -1 do
				local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
				if line:match("^%-%-%-$") then
					start_line = i
					break
				end
			end

			if not start_line then
				vim.notify("No slide separator (---) found above cursor", vim.log.levels.WARN)
				return
			end

			-- Search forward for next ^---$
			local end_line = nil
			for i = start_line + 1, total do
				local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
				if line:match("^%-%-%-$") then
					end_line = i
					break
				end
			end

			if not end_line then
				vim.notify("No closing slide separator (---) found below", vim.log.levels.WARN)
				return
			end

			-- Cut from start_line to end_line - 1 (exclude second ---)
			local cut_end = end_line - 1
			local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, cut_end, false)
			vim.fn.setreg('"', lines, "l")
			vim.fn.setreg("+", lines, "l")
			vim.api.nvim_buf_set_lines(buf, start_line - 1, cut_end, false, {})
			vim.notify("Cut " .. #lines .. " lines (slide)")
		end, { buffer = ev.buf, desc = "Cut markdown slide" })
	end,
})

return {
	-- In markdown: only show spell suggestions, not LSP/buffer/snippet noise
	{
		"saghen/blink.cmp",
		dependencies = { "ribru17/blink-cmp-spell" },
		opts = {
			sources = {
				per_filetype = {
					markdown = { "spell" },
				},
				providers = {
					spell = {
						name = "Spell",
						module = "blink-cmp-spell",
						opts = {},
					},
				},
			},
		},
	},

	-- Load markdown snippets from luasnippets/ directory
	{
		"L3MON4D3/LuaSnip",
		config = function()
			require("luasnip.loaders.from_lua").load({
				paths = { vim.fn.stdpath("config") .. "/luasnippets" },
			})
		end,
	},

	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = {
			linters_by_ft = {
				markdown = false, -- Disables linting for markdown files
			},
		},
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {
			render_modes = { "n", "i", "c", "t" },
			max_file_size = 999.0,

			heading = {
				enabled = false,
			},

			code = {
				enabled = true,
				sign = false,
				style = "normal",
				left_pad = 1,
				right_pad = 1,
				width = "block",
				border = "none",
			},

			bullet = {
				enabled = true,
				icons = { "•", "◦", "▸", "▹" },
				right_pad = 1,
			},

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
				border = {
					"┌",
					"┬",
					"┐",
					"├",
					"┼",
					"┤",
					"└",
					"┴",
					"┘",
					"│",
					"─",
				},
				alignment_indicator = "━",
				head = "RenderMarkdownTableHead",
				row = "RenderMarkdownTableRow",
			},
		},
	},

	{
		"Thiago4532/mdmath.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		cond = (vim.uv or vim.loop).os_uname().sysname == "Darwin",
		opts = {
			filetypes = { "markdown" },
		},

		-- The build is already done by default in lazy.nvim, so you don't need
		-- the next line, but you can use the command `:MdMath build` to rebuild
		-- if the build fails for some reason.
		-- build = ':MdMath build'
	},

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

  {
    "epwalsh/obsidian.nvim",
    version = "*",  -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   "BufReadPre path/to/my-vault/*.md",
    --   "BufNewFile path/to/my-vault/*.md",
    -- },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",

      -- see below for full list of optional dependencies 👇
    },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/obsidian",
        },
      },

      -- see below for full list of options 👇
    },
  }
}
