# minimal nvim config

Lightweight Neovim config for quick editing on macOS and Linux. No LSP, no treesitter highlights — just a fast editor with decent markdown support.

## Install

```bash
ln -sfn /path/to/dotfiles/nvim/minimal ~/.config/nvim
nvim  # first launch installs plugins; quit and reopen
```

## Plugins

| Plugin | Purpose |
|--------|---------|
| catppuccin | colorscheme (dark/light toggle) |
| lualine | statusline |
| telescope | fuzzy file/grep finder |
| which-key | keybind hints |
| neo-tree | file explorer |
| nvim-treesitter | markdown parser (for render-markdown only) |
| render-markdown | code block backgrounds, tables, checkboxes |
| marp-nvim | Marp slide preview server |
| LuaSnip | snippets (loads `luasnippets/`) |

## Keymaps

| Key | Action |
|-----|--------|
| `<leader>ut` | Toggle dark/light theme |
| `<leader>e` | Toggle file explorer |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<M-s>` | Save file |
| `;` / `:` | Swapped (`;` enters command mode) |

### Markdown

| Key | Action |
|-----|--------|
| `]]` / `[[` | Next/prev `##` heading |
| `]h` / `[h` | Next/prev heading (any level) |
| `<leader>mx` | Toggle checkbox |
| `<leader>mc` | New checkbox |
| `<leader>m>` / `<leader>m<` | Increase/decrease heading level |
| `<leader>MT` | Marp toggle |
| `<leader>MS` | Marp status |
| `<leader>xs` | Cut current slide (between `---` separators) |

## Notes

- **First launch**: treesitter parsers install in the background via `:TSUpdate`; quit and reopen for full markdown rendering.
- **Linux/HPC**: LSP, Mason, and animations are disabled automatically. Performance options (swap, updatetime) are tuned for remote use.
- **Theme persistence**: dark/light state is stored in `~/.lighttheme` (present = light, absent = dark).
- **Spell checking**: enabled for markdown and tex files; use `z=` for suggestions.
