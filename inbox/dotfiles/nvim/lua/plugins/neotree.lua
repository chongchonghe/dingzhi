-- lua/plugins/neotree.lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        hide_gitignored = false, -- show files ignored by .gitignore
        -- keep the others as you like:
        hide_dotfiles = false,   -- set true if you want dotfiles hidden
        hide_hidden = true,     -- OS hidden files
      },
    },
  },
}

