-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Swap ; and : in normal mode
-- noremap = true avoids recursion
vim.keymap.set("n", ";", ":", { noremap = true })
vim.keymap.set("n", ":", ";", { noremap = true })

vim.keymap.set({ "n", "i" }, "<M-s>", "<cmd>w<cr>", { desc = "Save file" })

-- Markdown heading navigation (buffer-local, set via autocmd)
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(ev)
		local buf = ev.buf
		local opts = function(desc)
			return { buffer = buf, silent = true, desc = desc }
		end

		-- Jump between headings
		vim.keymap.set("n", "]]", function()
			vim.fn.search("^##\\+\\s", "W")
		end, opts("Next heading"))
		vim.keymap.set("n", "[[", function()
			vim.fn.search("^##\\+\\s", "bW")
		end, opts("Previous heading"))
		-- Jump to any heading (including h1)
		vim.keymap.set("n", "]h", function()
			vim.fn.search("^#\\+\\s", "W")
		end, opts("Next heading (any level)"))
		vim.keymap.set("n", "[h", function()
			vim.fn.search("^#\\+\\s", "bW")
		end, opts("Previous heading (any level)"))

		-- Toggle checkbox
		vim.keymap.set("n", "<leader>mx", function()
			local line = vim.api.nvim_get_current_line()
			if line:match("%- %[ %]") then
				vim.api.nvim_set_current_line((line:gsub("%- %[ %]", "- [x]", 1)))
			elseif line:match("%- %[x%]") then
				vim.api.nvim_set_current_line((line:gsub("%- %[x%]", "- [ ]", 1)))
			end
		end, opts("Toggle checkbox"))

		-- Insert new checkbox
		vim.keymap.set("n", "<leader>mc", "o- [ ] ", opts("New checkbox"))

		-- Increase/decrease heading level
		vim.keymap.set("n", "<leader>m>", "I#<Esc>", opts("Increase heading level"))
		vim.keymap.set("n", "<leader>m<", function()
			local line = vim.api.nvim_get_current_line()
			if line:match("^##") then
				vim.api.nvim_set_current_line(line:sub(2))
			end
		end, opts("Decrease heading level"))

    -- marp markdown 
    vim.keymap.set("n", "<leader>MT", "<cmd>MarpToggle<cr>", { noremap = true, silent = true })
    vim.keymap.set("n", "<leader>MS", "<cmd>MarpStatus<cr>", { noremap = true, silent = true })
	end,
})
