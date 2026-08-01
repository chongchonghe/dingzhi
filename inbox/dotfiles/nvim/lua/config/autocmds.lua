-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Remove distracting keyword/operator highlights in shell scripts (Linux only, no treesitter)
if (vim.uv or vim.loop).os_uname().sysname ~= "Darwin" then
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

-- Markdown-specific settings for note-taking
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
		vim.opt_local.spell = true
		vim.opt_local.spelllang = "en_us"
		-- conceallevel=2 hides markup for Obsidian wiki links (macOS only)
		if (vim.uv or vim.loop).os_uname().sysname == "Darwin" then
			vim.opt_local.conceallevel = 2
		end
		vim.opt_local.shiftwidth = 2
		vim.opt_local.tabstop = 2
	end,
})

-- Turn on wrap in all diff windows (including when entering diff from inside nvim)
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


-- Remove LazyVim's auto-format on save; disable semantic tokens
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].formatexpr = nil
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})
-- lua/config/autocmds.lua

-- Make split separators visible on dark themes
-- Use UIEnter to ensure this runs after colorscheme is fully loaded
vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#5fffff", bg = "NONE", bold = true })
  end,
})

-- Also set on ColorScheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#5fffff", bg = "NONE", bold = true })
  end,
})

