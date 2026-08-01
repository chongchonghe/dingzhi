# dingzhi — Design

**Date:** 2026-08-01
**Status:** Approved, ready for implementation planning

## Purpose

`dingzhi` (定制) turns a fresh macOS or Linux machine into a fully configured
terminal development environment with one command. It packages the generic,
reusable parts of `~/tools` — app installers, dotfiles, and CLI utilities — into
a standalone repository that anyone can clone and install.

The philosophy is taken from [omakub](https://omakub.org): opinionated defaults,
one command, small single-purpose install scripts, a `gum` TUI for the few real
choices, and a post-install menu command. dingzhi differs from omakub in three
ways: it supports macOS and Linux (omakub is Ubuntu-only), it supports machines
without root (HPC login nodes), and it symlinks configs rather than copying them.

## Relationship to `~/tools`

`~/tools` remains the author's personal repository and continues unchanged.
dingzhi is a clean, generic distribution derived from it. There is no automated
sync: improvements are ported between the two by hand.

dingzhi lives at `extern/dingzhi` as a **nested git repository** with its own
`.git`, gitignored by `~/tools`. It gets its own GitHub remote when ready to
publish.

## Non-goals

- **No theme switcher.** Catppuccin Mocha, dark only. Live theme switching across
  nested TUIs (kitty → tmux → nvim → lazygit → vifm) is fragile and has caused
  ongoing frustration. The existing `~/.darktheme` toggle convention and
  `bin/toggle-theme` are deliberately not ported.
- **No GUI applications.** Terminal environment only.
- **No astro/HPC/academic tooling.** Stays in `~/tools`.
- **No machine-specific configuration.** `rc/`, `my-computers/`, and the
  machine-named shell files stay in `~/tools`.
- **No migrations directory.** Idempotent installers make versioned migrations
  unnecessary.
- **No user-facing config file.** Personalization beyond the first-run prompts
  means forking, as in omakub.

## Platform support

| Platform | Backend | Binary destination |
|---|---|---|
| macOS | Homebrew | Homebrew prefix |
| Linux, Debian-family, sudo available | `apt` | `/usr/local/bin` |
| Linux, otherwise (incl. HPC, RHEL) | `eget` + `pixi` | `~/local/bin` |

Backend detection happens once, in `lib/detect.sh`, and sets `DINGZHI_BACKEND`
to `brew`, `apt`, or `noroot`, plus `DINGZHI_BIN`.

## Architecture

### Directory layout

```
dingzhi/
  boot.sh                    # curl | bash entry point
  install.sh                 # orchestrator
  version
  lib/
    detect.sh                # OS, distro, sudo, arch → DINGZHI_BACKEND, DINGZHI_BIN
    pkg.sh                   # pkg_install / pkg_remove / pkg_installed + name table
    link.sh                  # manage_symlink (ported from dotfiles/setup.sh)
    ui.sh                    # gum wrappers, plain-text fallback when gum is absent
  install/
    check-system.sh          # abort early on unsupported platforms
    bootstrap.sh             # install the backend itself, then gum
    choices.sh               # gum first-run prompts
    identification.sh        # git name/email → ~/.gitconfig.local
  apps/
    <name>/install.sh        # required
    <name>/uninstall.sh      # optional; presence gates the TUI Remove entry
  configs/                   # dotfiles, symlinked into place
    shell/                   # init.sh, env.sh, aliases.sh, functions.sh, platform.sh
    kitty/ nvim/ tmux/ yazi/ vifm/ bat/ lazygit/ cheat/ git/
  themes/catppuccin/         # vendored color files referenced by configs
  bin/
    dingzhi                  # gum TUI menu
    myconvert compressimage  # the 2 shipped CLI utilities
  tests/
    Dockerfile.ubuntu-sudo
    Dockerfile.ubuntu-nosudo
```

### The `pkg` abstraction

The technical crux is three install backends × ~34 apps. Rather than branching on
platform inside every app script (as `~/tools` does today), `lib/pkg.sh` exposes:

- `pkg_install <name>` — resolve `<name>` for the active backend and install it
- `pkg_remove <name>`
- `pkg_installed <name>` — predicate, for idempotency and `doctor`

Resolution comes from a single table mapping a generic name to its per-backend
identity. For example `fd` is `fd` on Homebrew, `fd-find` on apt, and
`sharkdp/fd` with asset filter `x86_64-unknown-linux-gnu.tar.gz` under eget.
Packages that must be compiled on the no-root path (tmux, stow, cmake, vim) route
to `pixi global install` instead of eget.

Consequence: adding apt support for every app is a table edit, not 34 script
edits. Each `apps/<name>/install.sh` reduces to `pkg_install <name>` followed by
whatever config or symlink work that app needs.

Every app script is idempotent — running it twice is a no-op the second time.

### Path handling

`DINGZHI_PATH` is derived from `BASH_SOURCE` at runtime. No absolute path to a
particular home directory or checkout location appears anywhere. A user who
clones to somewhere other than `~/.local/share/dingzhi` still works.

### Configs are symlinked, not copied

`lib/link.sh` ports the `manage_symlink` helper from `dotfiles/setup.sh`
unchanged in behavior: it skips symlinks already pointing at the right target,
backs up any real file it would displace to `<file>.backup.<timestamp>`, and
supports removal. Because configs are symlinks into the checkout, `git pull`
updates them live.

## Install flow

`curl -fsSL <url>/boot.sh | bash`:

1. **boot.sh** — clone to `~/.local/share/dingzhi`, source `install.sh`
2. **check-system.sh** — macOS, or Linux with glibc; abort otherwise with a clear
   message naming what was detected
3. **detect.sh** — set `DINGZHI_BACKEND` and `DINGZHI_BIN`
4. **bootstrap.sh** — install the backend (Homebrew, or eget + pixi), then `gum`.
   Everything after this point may use the TUI.
5. **choices.sh** — the only prompts: which app groups (all selected by default),
   and which shell to configure (zsh default, bash optional). Choices are
   persisted to `~/.local/state/dingzhi/choices` so re-runs and the `dingzhi`
   menu are idempotent.
6. **identification.sh** — git name and email → `~/.gitconfig.local`
7. **Apps** — loop `apps/*/install.sh` for selected groups
8. **Dotfiles** — `link.sh` symlinks `configs/` into place
9. **Shell init** — append a single marker-guarded `source` line to `~/.zshrc`
   and/or `~/.bashrc`

Steps 5 and 6 are the only interactive points. Setting `DINGZHI_NONINTERACTIVE=1`
accepts all defaults and skips the git identity prompt.

## Contents

### Apps (34)

Each table row below is one **group**, and groups are the unit `choices.sh`
offers at first run. All groups are selected by default.

| Group | Apps |
|---|---|
| Core CLI | `bat` `eza` `fd` `fzf` `ripgrep` `zoxide` `git-delta` `jq` `tlrc` `trash-cli` `stow` `thefuck` `highlight` |
| Terminal | `kitty` `tmux` |
| Editors | `neovim` `vim` |
| Git | `git` (config only) `lazygit` `gh` |
| File managers | `yazi` `vifm` |
| Shell | `zsh` (oh-my-zsh + powerlevel10k), `bash` (oh-my-bash) |
| Dev | `uv` `cmake` |
| Media | `pandoc` `poppler` `imagemagick` `ffmpeg` `pngquant` `jpegoptim` `webp` |
| Misc | `cheat` |

Both shells ship: zsh is the default and the mature config, but bash matters on
HPC systems where the login shell cannot be changed. `choices.sh` asks which to
configure; the answer determines which init file gets the source line.

**Excluded:** `quokka` `pymses` `yt` `yt_idv` `yt-studio` `gravidy` `mcluster`
`petar` `radmc3d` `ramtools` `skirt` `globusconnectpersonal` (astro/HPC);
`python-base` (Setonix-only); `tools` (a Makefile); `emacs` (heavy, opinion-dense
install and a deeply personal doom config — out of v1, reconsider if requested);
`obsidian` `typora` `ticktick` `syncthing` `markdown-marp` `calc` (GUI or no
install script).

### Configs

Shipped and symlinked: `kitty` `nvim` `tmux` `yazi` `vifm` `bat` `lazygit`
`cheat` `git` `shell`.

**Excluded:** `iTerm2` `ghostty` `Rectangle` `raycast` `spacemacs` `vscode`
`markdown-themes` `org-styles` `mbsync` `doom` — machine-, GUI-, or
workflow-specific.

Two required changes to shipped configs:

1. **Git identity.** `configs/git/gitconfig` ships without a `[user]` section and
   `[include]`s `~/.gitconfig.local`, which `identification.sh` writes from the
   first-run prompt. The current file hardcodes a name and email.
2. **Delta theme path.** The current gitconfig `[include]`s
   `~/git/catppuccin/delta/catppuccin.gitconfig`, an absolute path into a
   personal checkout that will not exist on anyone else's machine. dingzhi
   vendors that file into `themes/catppuccin/` and includes it by
   `$DINGZHI_PATH`-relative path.

### Shell architecture

`configs/shell/init.sh` is the single entry point, sourced from `~/.zshrc` or
`~/.bashrc`. It sources, in order:

1. `env.sh` — PATH (`$DINGZHI_PATH/bin`, `~/local/bin`, `~/.local/bin`,
   `~/.pixi/bin`), shared exports
2. `aliases.sh`
3. `functions.sh`
4. `platform.sh` — dispatches to the macOS or Linux variant

This mirrors the existing `shared.bashrc` structure. Changes from the original:
`$HOME/tools/bin` becomes `$DINGZHI_PATH/bin`; the `RC_HOME`, `MOVE_ROOT`, and
`MOVE_JSON` exports are dropped (they belong to tooling that is not shipping);
the two personal aliases in `shared.mac.zshrc` (`md2org`, which references
`~/Documents/computer/pandoc/`, and `qk`, which aliases `quokka`) are dropped.

### `bin/` utilities (2)

The `~/tools/bin` collection is overwhelmingly personal. Only two scripts ship:

- **`myconvert`** — universal file format converter (documents, images, video,
  audio, data) routing to pandoc, poppler, ImageMagick, and ffmpeg
- **`compressimage`** — batch image compressor for publication figures
  (pngquant / jpegoptim / cwebp), with optional resizing

Everything else in `bin/` stays in `~/tools`.

`myconvert` requires one fix: `MARKER_VENV` is hardcoded to
`/Users/cche/softwares/python-envs/pdf/bin/activate`. dingzhi reads it from
`$MYCONVERT_MARKER_VENV` instead, defaulting to unset; `--force-marker` then
fails with a message explaining how to point it at a marker install. The marker
path is the only feature that degrades — every other conversion route works from
the shipped dependencies.

Both scripts already `require`-check their tools and print install hints, but a
distribution should not ship a command that does not work on first use.
Their dependencies therefore ship as a **media** group: `pandoc` `poppler`
`imagemagick` `ffmpeg` `pngquant` `jpegoptim` `webp`. All seven are available on
Homebrew, apt, and conda-forge, so the group installs on all three backends.
This brings the app total to 34.

### Not shipped

`rc/` `raycast_scripts/` `my-computers/` `programs/` `scripts/`
`simple_scripts/` `managed/`, and all machine-named shell files (`MBA.zshrc`,
`macstudio.zshrc`, `gadi`, `setonix`, `zaratan`, …).

## The `dingzhi` command

`bin/dingzhi` opens a gum menu with four entries:

- **Install** — lists apps not currently installed; runs their `install.sh`
- **Remove** — lists **only** apps that ship an `uninstall.sh`. This is the
  contract: `uninstall.sh` is optional, and the menu is honest about what it can
  undo. Uninstall scripts are written for the ~15 apps where removal is a
  one-liner (`pkg_remove` plus unlinking a config); the rest are install-only.
  Omakub hand-wrote 41 uninstall scripts; shipping fewer well-tested ones is the
  better trade.
- **Update** — `git pull` then re-run `install.sh`
- **Doctor** — a table, one row per app: installed? config linked? shell init
  line present? Also reports the detected backend and `DINGZHI_PATH`.

`dingzhi <subcommand>` works non-interactively for `update` and `doctor`.

## Error handling

- `install.sh` runs with `set -e` and an `ERR` trap printing the exact command to
  retry, matching omakub.
- Unsupported platform aborts in `check-system.sh` before anything is written.
- A failing individual app installer is reported and skipped rather than aborting
  the whole run; the summary at the end lists what failed.
- `manage_symlink` never destroys a real file — it backs up to
  `<file>.backup.<timestamp>` and reports every backup in the run summary.
- `ui.sh` falls back to plain `read`-based prompts if `gum` is unavailable, so a
  failed gum bootstrap does not make the installer unusable.

## Verification

Not a unit test suite. `tests/` holds two Dockerfiles:

- `Dockerfile.ubuntu-sudo` — Ubuntu 24.04, user with sudo → exercises the `apt`
  backend
- `Dockerfile.ubuntu-nosudo` — Ubuntu 24.04, unprivileged user → exercises the
  `noroot` (eget + pixi) backend

Each runs `install.sh` twice non-interactively and asserts: the first run
succeeds, the second run succeeds and reports every step as already-done
(idempotency), and `dingzhi doctor` reports no missing items.

**Hard constraint: no installer, app script, or `link.sh` invocation is ever run
on the author's working machine.** dingzhi writes to `~/.config`, `~/.zshrc`,
`~/.gitconfig`, and `~/local/bin` — the same paths `~/tools` already owns — and
running it locally would displace live configuration. All Linux verification
happens inside the containers above. The macOS backend is written and reviewed
by reading, and verified later on a clean machine or VM, not during development.

Success criteria for v1: on a fresh Ubuntu 24.04 container, one command produces
a working kitty/tmux/nvim/zsh environment with Catppuccin theming; the same
command on a non-sudo container produces the same environment under
`~/local/bin`; both are idempotent on re-run.

## Known issues in the source repo

Not fixed as part of this work, noted for the record:

- `apps/macos_install.sh` and `apps/hpc_install.sh` both call
  `run_config shell`, but `apps/shell/` does not exist — it silently skips.
