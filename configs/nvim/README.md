# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Config Operations

### Applying changes

| Change type | How to apply |
|---|---|
| Plugin added/removed/enabled/disabled | Full restart |
| `options.lua` | `:source $MYVIMRC` or restart |
| `autocmds.lua` / `keymaps.lua` | `:source $MYVIMRC` or restart |
| LSP config | `:LspRestart` or restart |

When in doubt, just restart — it always works.

### Useful commands

| Command | What it does |
|---|---|
| `:Lazy` | Open plugin manager (update, clean, sync) |
| `:Lazy sync` | Install missing + remove unused plugins |
| `:Mason` | Manage LSP/linter/formatter installs |
| `:LspInfo` | Show attached LSP clients for current buffer |
| `:LspRestart` | Restart LSP without leaving Neovim |
| `:checkhealth` | Diagnose common issues |
| `:Telescope keymaps` | Browse all active keymaps |

### Where to add things

| What | File |
|---|---|
| Editor options (`vim.opt.*`) | `lua/config/options.lua` |
| Keymaps | `lua/config/keymaps.lua` |
| Autocommands | `lua/config/autocmds.lua` |
| New plugin or plugin override | `lua/plugins/<name>.lua` |
| UI / visual tweaks | `lua/plugins/ui.lua` |

## Themes

### Colorscheme

Catppuccin Mocha, dark only. dingzhi ships a single theme across every
app; there is no light variant and no toggle command.


## Markdown Rendering

Enhanced markdown rendering with `render-markdown.nvim`:

- **Heading icons**: Beautiful icons for H1-H6 ('󰼏 ', '󰎨 ', '󰼑 ', '󰎲 ', '󰼓 ', '󰎴 ')
- **Indentation**: Org-mode style indentation (2 spaces per level)
- **No file size limit**: Disabled to handle large markdown files
- **Render modes**: Active in normal, command, and terminal modes

# Markdown format demo

> [!NOTE]
> this is a > [!NOTE]

how about it?

Checkbox

- [ ] haha1
- [ ] haha2


