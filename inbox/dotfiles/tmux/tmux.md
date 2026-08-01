# tmux Reference

## Keybindings

Prefix: **C-s** (Control+s)

### Panes

| Key | Action |
|-----|--------|
| `\` | Split horizontal |
| `-` | Split vertical |
| `M-h` / `M-j` / `M-k` / `M-l` | Switch pane (vim-style, no prefix) |
| `y` | Copy mode |
| `p` | Paste buffer |

### Windows

| Key | Action |
|-----|--------|
| `M-,` | Previous window |
| `M-.` | Next window |
| `M-0` … `M-9` | Select window by index |
| `M-<` | Swap window backward |
| `M->` | Swap window forward |
| `prefix ,` | Rename window |

### Sessions

| Key | Action |
|-----|--------|
| `M-P` (Alt+Shift+p) | Previous session |
| `M-N` (Alt+Shift+n) | Next session |
| `prefix s` | Session picker |
| `prefix $` | Rename session |

### Config

| Key | Action |
|-----|--------|
| `prefix r` | Reload config |

---

## Commands (CLI)

### Config reload

```bash
# From inside or outside tmux
tmux source-file ~/.config/tmux/tmux.conf
```

Full reset (kills all sessions):

```bash
tmux kill-server
tmux
```

### Session naming

```bash
# Create session with name
tmux new -s my-session

# Rename session
tmux rename-session -t old-name new-name

# Rename current session
tmux rename-session new-name
```

### Move window between sessions

**Entire window (all panes):**
```bash
tmux link-window -s source:window -t target:index
tmux unlink-window -t source:window
```

**Single pane only:**
```bash
tmux join-pane -s source:window -t target:window
```

**Example:**
```bash
tmux link-window -s qk:decra -t cv-and-proposal:0
tmux unlink-window -t qk:decra
```

---

## set-option flags

| Flag | Meaning |
|------|---------|
| `-a` | **Append** – add to existing value instead of replacing |
| `-g` | **Global** – apply to session |
| `-F` | **Format expansion** – expand `#{...}` and `#{E:...}` before setting |

Example: `set -agF status-right "..."` appends and expands formats.

---

## Status options

### Main options

| Option | Description | Default |
|--------|-------------|---------|
| `status` | Show/hide (`on`/`off`) | on |
| `status-position` | `top` or `bottom` | bottom |
| `status-interval` | Refresh interval (seconds) | 15 |
| `status-justify` | Window list: `left`, `centre`, `right` | left |
| `status-style` | Overall styling | — |
| `status-left` | Left content | `[#S] ` |
| `status-left-length` | Max left length | 10 |
| `status-left-style` | Left section style | default |
| `status-right` | Right content | — |
| `status-right-length` | Max right length | 40 |
| `status-right-style` | Right section style | default |

### Window list options

| Option | Description |
|--------|-------------|
| `window-status-format` | Inactive window format |
| `window-status-current-format` | Active window format |
| `window-status-activity-style` | Activity indicator style |
| `window-status-bell-style` | Bell indicator style |

### Format variables

| Variable | Meaning |
|----------|---------|
| `#S` | Session name |
| `#W` | Window name |
| `#T` | Pane title |
| `#H` | Hostname |
| `#I` | Window index |
| `%H:%M` | Time (strftime) |

View current settings:

```bash
tmux show-options -g | grep status
```

---

## Catppuccin plugin

### Themes (flavors)

| Flavor | Option |
|--------|--------|
| Latte | `set -g @catppuccin_flavor "latte"` (light) |
| Frappé | `set -g @catppuccin_flavor "frappe"` |
| Macchiato | `set -g @catppuccin_flavor "macchiato"` |
| Mocha | `set -g @catppuccin_flavor "mocha"` (dark, default) |

**Auto dark/light (macOS):** tmux.conf checks `defaults read -g AppleInterfaceStyle` at startup – Dark → mocha, otherwise → latte. Theme changes when system appearance changes require restarting tmux or `prefix r`.

### Status line modules

| Module | Variable | Requires |
|--------|----------|----------|
| Session | `#{E:@catppuccin_status_session}` | — |
| Directory | `#{E:@catppuccin_status_directory}` | — |
| Application | `#{E:@catppuccin_status_application}` | — |
| Uptime | `#{E:@catppuccin_status_uptime}` | — |
| Date/Time | `#{E:@catppuccin_status_date_time}` | — |
| Host | `#{E:@catppuccin_status_host}` | — |
| User | `#{E:@catppuccin_status_user}` | — |
| Load | `#{E:@catppuccin_status_load}` | — |
| CPU | `#{E:@catppuccin_status_cpu}` | tmux-cpu |
| Battery | `#{E:@catppuccin_status_battery}` | tmux-battery |
| Gitmux | `#{E:@catppuccin_status_gitmux}` | gitmux |
| Weather | `#{E:@catppuccin_status_weather}` | tmux-weather |
| Clima | `#{E:@catppuccin_status_clima}` | tmux-clima |
| Pomodoro | `#{pomodoro_status}` (see below) | tmux-pomodoro-plus |
| Kube | `#{E:@catppuccin_status_kube}` | tmux-kubectx |

### Window options

| Option | Values | Effect |
|--------|--------|--------|
| `@catppuccin_window_status_style` | `basic`, `rounded`, `slanted`, `custom`, `none` | Window tab style |
| `@catppuccin_window_text` | format string | Inactive window label (default `#T`) |
| `@catppuccin_window_current_text` | format string | Active window label (default `#T`), use `#W` for window name |
| `@catppuccin_window_number_position` | `left`, `right` | Window index position |
| `@catppuccin_window_flags` | `none`, `icon`, `text` | Activity/bell/zoom etc. indicators |

### Status bar options

| Option | Effect |
|--------|--------|
| `@catppuccin_status_background` | `default`, `none`, or hex/theme color |
| `@catppuccin_status_left_separator` | Left separator |
| `@catppuccin_status_right_separator` | Right separator |

### Pane options

| Option | Effect |
|--------|--------|
| `@catppuccin_pane_status_enabled` | `yes`/`no` – pane border content |
| `@catppuccin_pane_border_status` | `on`/`off` |
| `@catppuccin_pane_default_text` | Pane border text (default `#{b:pane_current_path}`) |

### Module customization

```bash
set -g @catppuccin_[module_name]_icon "icon"
set -g @catppuccin_[module_name]_color "color"
set -g @catppuccin_[module_name]_text "text"
set -g @catppuccin_status_[module_name]_bg_color "#{@thm_surface_0}"
```

### tmux-pomodoro-plus: literal replacement

The pomodoro plugin works by finding the literal string `#{pomodoro_status}` in `status-right`/`status-left` and replacing it with `#(/path/to/pomodoro.sh)` when it loads. Two implications:

1. **Use `#{pomodoro_status}` directly** – Don't use `#{E:@catppuccin_status_pomodoro_plus}`; the `#{pomodoro_status}` is buried inside that option so the plugin never sees it and the literal text appears.

2. **Load order** – Set `status-right` *before* TPM runs. The plugin runs when TPM loads it; if `status-right` is set after TPM, the plugin's replacement gets overwritten.

```bash
# Set status-right before TPM
set -g status-right "#{pomodoro_status}"
set -ag status-right "#{E:@catppuccin_status_directory}"
# ...

# TPM must run last
run '~/.config/tmux/plugins/tpm/tpm'
```

The icon only appears when a pomodoro/break is active. Use `prefix p` to toggle.

### Example config

```bash
run '~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux'

set -g @catppuccin_flavor "mocha"
set -g @catppuccin_window_status_style "rounded"
set -g @catppuccin_window_text " #W"
set -g @catppuccin_window_current_text " #W"

set -g status-right "#{pomodoro_status}"  # literal for plugin replacement
set -ag status-right "#{E:@catppuccin_status_directory}"
set -ag status-right "#{E:@catppuccin_status_gitmux}"

run '~/.config/tmux/plugins/tpm/tpm'  # after status-right
```

---

## Window title notes

- Use `#W` for window name (respects `prefix ,` rename)
- Use `#T` for pane title (shell-set, often hostname/path)
- `setw -g automatic-rename off` keeps manual renames from being overwritten by the shell
