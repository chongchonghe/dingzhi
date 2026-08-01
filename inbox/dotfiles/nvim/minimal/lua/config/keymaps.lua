vim.keymap.set("n", ";", ":", { noremap = true })
vim.keymap.set("n", ":", ";", { noremap = true })

vim.keymap.set({ "n", "i" }, "<M-s>", "<cmd>w<cr>", { desc = "Save file" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(ev)
		local buf = ev.buf
		local opts = function(desc)
			return { buffer = buf, silent = true, desc = desc }
		end

		vim.keymap.set("n", "]]", function()
			vim.fn.search("^##\\+\\s", "W")
		end, opts("Next heading"))
		vim.keymap.set("n", "[[", function()
			vim.fn.search("^##\\+\\s", "bW")
		end, opts("Previous heading"))
		vim.keymap.set("n", "]h", function()
			vim.fn.search("^#\\+\\s", "W")
		end, opts("Next heading (any level)"))
		vim.keymap.set("n", "[h", function()
			vim.fn.search("^#\\+\\s", "bW")
		end, opts("Previous heading (any level)"))

		vim.keymap.set("n", "<leader>mx", function()
			local line = vim.api.nvim_get_current_line()
			if line:match("%- %[ %]") then
				vim.api.nvim_set_current_line((line:gsub("%- %[ %]", "- [x]", 1)))
			elseif line:match("%- %[x%]") then
				vim.api.nvim_set_current_line((line:gsub("%- %[x%]", "- [ ]", 1)))
			end
		end, opts("Toggle checkbox"))

		vim.keymap.set("n", "<leader>mc", "o- [ ] ", opts("New checkbox"))

		vim.keymap.set("n", "<leader>m>", "I#<Esc>", opts("Increase heading level"))
		vim.keymap.set("n", "<leader>m<", function()
			local line = vim.api.nvim_get_current_line()
			if line:match("^##") then
				vim.api.nvim_set_current_line(line:sub(2))
			end
		end, opts("Decrease heading level"))

		vim.keymap.set("n", "<leader>MT", "<cmd>MarpToggle<cr>", opts("Marp toggle"))
		vim.keymap.set("n", "<leader>MS", "<cmd>MarpStatus<cr>", opts("Marp status"))

		vim.keymap.set("n", "<leader>xs", function()
			local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
			local total = vim.api.nvim_buf_line_count(buf)

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

			local cut_end = end_line - 1
			local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, cut_end, false)
			vim.fn.setreg('"', lines, "l")
			vim.fn.setreg("+", lines, "l")
			vim.api.nvim_buf_set_lines(buf, start_line - 1, cut_end, false, {})
			vim.notify("Cut " .. #lines .. " lines (slide)")
		end, opts("Cut markdown slide"))
	end,
})
