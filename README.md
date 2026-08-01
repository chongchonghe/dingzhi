# dingzhi

Turn a fresh macOS or Linux machine into a fully configured terminal
development environment with one command.

```bash
curl -fsSL https://raw.githubusercontent.com/chongchonghe/dingzhi/main/boot.sh | bash
```

dingzhi is an opinionated take on a terminal setup: kitty, tmux, neovim, zsh,
lazygit, yazi, and a coherent set of modern CLI tools, all themed Catppuccin
Mocha, all configured to work together.

## What you get

| Group | Apps |
|---|---|
| core | bat, eza, fd, fzf, ripgrep, zoxide, delta, jq, tlrc, trash-cli, stow, thefuck |
| terminal | kitty, tmux |
| editors | neovim, vim |
| git | git, lazygit, gh |
| filemanagers | yazi, vifm |
| shell | zsh (oh-my-zsh + powerlevel10k), bash |
| dev | uv, cmake |
| media | pandoc, poppler, imagemagick, ffmpeg, pngquant, jpegoptim, webp |
| misc | cheat |

Plus two utilities: `myconvert`, which converts between document, image, video,
audio, and data formats, and `compressimage`, which batch-compresses
publication figures.

## Supported platforms

| Platform | How packages are installed |
|---|---|
| macOS | Homebrew |
| Ubuntu / Debian with sudo | apt, falling back to GitHub releases where a package does not exist |
| Any other Linux, including HPC login nodes | eget + pixi, entirely without root |

The third path never requires root. Binaries go to `~/local/bin`.

Two packages are unavailable there and say so rather than failing: `jpegoptim`
is not on conda-forge, so `compressimage` falls back to `cjpeg`/`djpeg` for
JPEG; and conda-forge's `vifm` has an osx-64 build only, so on Linux `yazi`
covers file management.

If you are behind a shared IP — an HPC login node NATs many users through one
address — export `GITHUB_TOKEN`, or run `gh auth login` first. Unauthenticated
GitHub API access is capped at 60 requests per hour per IP, and the no-root
path spends several of those.

## After installing

```bash
dingzhi            # interactive menu
dingzhi install    # install apps you skipped
dingzhi remove     # remove apps that can be cleanly removed
dingzhi update     # git pull and re-run the installer
dingzhi doctor     # report what is installed, linked, and configured
```

Re-running the installer is always safe: it changes nothing that is already
correct, and the test suite asserts that.

`dingzhi remove` lists only apps that ship an uninstall script. The rest are
install-only, because undoing them would mean reverting a login shell, deleting
terminfo, or touching a gitconfig that is now yours.

## Configuration

Configs live in `configs/` and are **symlinked** into `~/.config`, so
`dingzhi update` updates them in place. Any real file dingzhi would displace is
backed up to `<file>.backup.<timestamp>` first — it never overwrites.

Your git identity goes to `~/.gitconfig.local`, which the shipped gitconfig
includes. dingzhi never commits your name or email.

dingzhi is deliberately opinionated: the theme is Catppuccin Mocha, dark only,
with no switcher. Live theme switching across nested TUIs (kitty → tmux → nvim
→ lazygit → yazi) is fragile, and every layer has to agree. To change what it
installs or how it looks, fork it.

## Development

```bash
tests/docker-build.sh all                                  # build the test images
tests/docker-run.sh -- bash -c 'bats tests/unit'           # unit tests, apt backend
tests/docker-run.sh --nosudo -- bash -c 'bats tests/unit'  # unit tests, no-root backend
tests/docker-run.sh --gh-auth -- bash tests/integration/install-twice.sh
```

Three images: `dingzhi-sudo` exercises the apt backend, `dingzhi-nosudo` runs as
a user who cannot escalate, and `dingzhi-clean` omits the agentic-coding toolkit
so the installers for tools that toolkit provides (`gh`) can be tested honestly.
All are `linux/amd64`, matching every real dingzhi Linux target — an arm64
container would install x86_64 release binaries that cannot execute.

Never run the installer on your own machine while developing. It writes to
`~/.config`, `~/.zshrc`, and `~/.gitconfig`, the same paths your real
configuration uses. The containers exist for that reason.

## License

MIT
