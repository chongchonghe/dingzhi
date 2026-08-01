-- UI customizations and performance settings for HPC
local is_macos = (vim.uv or vim.loop).os_uname().sysname == "Darwin"
local is_ssh = os.getenv("SSH_CLIENT") ~= nil or os.getenv("SSH_TTY") ~= nil

-- Disable all animations on Linux or SSH
if not is_macos or is_ssh then
  vim.g.snacks_animate = false
end

return {
  -- Disable snacks.nvim scroll animation on Linux or SSH
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      if not is_macos or is_ssh then
        opts.scroll = { enabled = false }
      end
      -- Configure file explorer to show gitignored files
      if not opts.explorer then
        opts.explorer = {}
      end
      opts.explorer.hidden = false -- Show hidden files
      return opts
    end,
  },
  
  -- Disable mini.animate on Linux or SSH
  {
    "nvim-mini/mini.animate",
    enabled = is_macos and not is_ssh,
  },

  -- Disable LSP on Linux (doesn't work well on HPC)
  {
    "neovim/nvim-lspconfig",
    enabled = is_macos,
  },
  
  -- Disable Mason (LSP installer) on Linux
  {
    "mason-org/mason.nvim",
    enabled = is_macos,
  },
  
  {
    "mason-org/mason-lspconfig.nvim",
    enabled = is_macos,
  },

  -- Disable Treesitter on Linux (requires tree-sitter CLI)
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = is_macos,
  },

  -- Disable word-under-cursor highlighting (vim-illuminate)
  {
    "RRethy/vim-illuminate",
    enabled = false,
  },

  -- Disable TODO/FIXME comment highlighting
  {
    "folke/todo-comments.nvim",
    enabled = false,
  },

  -- Configure neo-tree to show gitignored files
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      opts.filesystem = opts.filesystem or {}
      opts.filesystem.filtered_items = {
        visible = true, -- Show hidden/filtered items by default
        hide_dotfiles = false,
        hide_gitignored = false, -- Show gitignored files
        hide_hidden = false, -- Only relevant on Windows
        hide_by_name = {},
        hide_by_pattern = {},
        always_show = {},
        never_show = {},
      }
      return opts
    end,
  },
}

