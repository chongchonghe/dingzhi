# dingzhi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `dingzhi`, a standalone repository that turns a fresh macOS or Linux machine into a fully configured terminal development environment with one command.

**Architecture:** An omakub-shaped bash distribution at `extern/dingzhi`. A `lib/` layer detects the platform and abstracts three package backends (Homebrew, apt+sudo, eget+pixi no-root) behind `pkg_install`. Each app is a small idempotent `apps/<name>/install.sh` that calls `pkg_install` and does its own config work. Configs are symlinked from `configs/` into `~/.config` so `git pull` updates them live. A `bin/dingzhi` gum TUI handles install/remove/update/doctor after the first run.

**Tech Stack:** Bash, [gum](https://github.com/charmbracelet/gum) for the TUI, [eget](https://github.com/zyedidia/eget) and [pixi](https://pixi.sh) for no-root installs, Homebrew on macOS, apt on Debian-family Linux, [bats-core](https://github.com/bats-core/bats-core) for tests, Docker for verification.

**Spec:** [`design.md`](design.md)

---

## Global Constraints

These apply to every task. Violating any of them is grounds for rejecting the task.

1. **Bash 3.2 compatible.** macOS ships bash 3.2 as `/bin/bash`. No associative arrays (`declare -A`), no `${var^^}` / `${var,,}` case modification, no `mapfile`/`readarray`, no `**` globstar, no `[[ -v var ]]`. Use `case` statements instead of associative arrays. Every script starts `#!/usr/bin/env bash`.
2. **Never run installers on the development machine.** dingzhi writes to `~/.config`, `~/.zshrc`, `~/.gitconfig`, and `~/local/bin` — the same paths `~/tools` already owns. All Linux verification happens inside the Docker containers from Task 1. The macOS backend is written and reviewed by reading only.
3. **No absolute paths to a particular home or checkout.** `DINGZHI_PATH` is always derived from `BASH_SOURCE` at runtime. No `/Users/...`, no `$HOME/tools`.
4. **Every install script is idempotent.** Running it a second time must succeed, change nothing, and say so.
5. **Tests never touch the real `$HOME`.** Every bats test sets `HOME="$BATS_TEST_TMPDIR/home"` in `setup()`.
6. **Theme is Catppuccin Mocha, dark only.** No light variant, no theme switcher, no `~/.darktheme` toggle.
7. **Commit after every task** using Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`).
8. **Work inside `extern/dingzhi`**, which is its own git repository. All `git` commands in this plan run from `extern/dingzhi`.
9. **Porting source lives in `inbox/`.** Tasks 9, 11, and 13 copy configs and scripts from `inbox/`, which is committed to this repository so it travels with any checkout or container. Copy *out* of it; never edit it in place. Delete `inbox/` once Task 13 is done — Task 18 checks that it is gone.

### Canonical group names

Used by `choices.sh`, the app loop, and the TUI. Exact strings:

`core` `terminal` `editors` `git` `filemanagers` `shell` `dev` `media` `misc`

### Canonical backend names

Exact values of `DINGZHI_BACKEND`: `brew` `apt` `noroot`

---

## File Structure

```
extern/dingzhi/
  .gitignore
  README.md
  version                          # single line, e.g. "0.1.0"
  boot.sh                          # curl | bash entry point
  install.sh                       # orchestrator
  lib/
    detect.sh                      # DINGZHI_OS, DINGZHI_BACKEND, DINGZHI_BIN, DINGZHI_PATH
    pkg.sh                         # pkg_install / pkg_remove / pkg_installed / pkg_resolve
    link.sh                        # manage_symlink, unlink_managed
    ui.sh                          # say / warn / die / choose_multi / prompt
  install/
    check-system.sh
    bootstrap.sh
    choices.sh
    identification.sh
  apps/
    <name>/install.sh              # 34 apps
    <name>/uninstall.sh            # ~15 apps
  configs/
    shell/{init,env,aliases,functions,platform,mac,linux}.sh
    git/{gitconfig,gitignore_global}
    kitty/ nvim/ tmux/ yazi/ vifm/ bat/ lazygit/ cheat/
  themes/catppuccin/               # delta gitconfig, vendored color files
  bin/
    dingzhi                        # TUI
    myconvert
    compressimage
  tests/
    Dockerfile                     # ARG WITH_SUDO
    docker-build.sh
    docker-run.sh
    integration/install-twice.sh
    helpers.bash
    unit/*.bats
```

Responsibilities are single-purpose by file: `detect.sh` only sets variables and never installs; `pkg.sh` only installs packages and never writes configs; `link.sh` only manages symlinks; `ui.sh` only prints and prompts. App scripts are the only place those layers combine.

---

### Task 1: Repository skeleton and Docker test harness

Nothing else can be verified until there is a container to verify it in. This task produces a buildable image containing Claude Code, and a test runner that passes on an empty test suite.

**Files:**
- Create: `extern/dingzhi/.gitignore`
- Create: `extern/dingzhi/version`
- Create: `extern/dingzhi/README.md`
- Create: `extern/dingzhi/tests/Dockerfile`
- Create: `extern/dingzhi/tests/docker-build.sh`
- Create: `extern/dingzhi/tests/docker-run.sh`
- Create: `extern/dingzhi/tests/helpers.bash`
- Create: `extern/dingzhi/tests/unit/smoke.bats`
- Create: `extern/dingzhi/start-in-docker.md`
- Create: `extern/dingzhi/docs/{design,plan}.md` (this plan and the spec)
- Create: `extern/dingzhi/inbox/` (porting source: ten config directories, two
  scripts, and the catppuccin delta theme)
- Modify: `/Users/u1149259/tools/.gitignore` (add `extern/dingzhi/`)

**Interfaces:**
- Consumes: nothing
- Produces: `tests/helpers.bash` exporting `setup_dingzhi_env()`, which sets `HOME="$BATS_TEST_TMPDIR/home"`, `DINGZHI_PATH` to the repo root, and creates `$HOME`. Every later `.bats` file calls it in `setup()`.

- [ ] **Step 1: Create the nested git repository**

```bash
mkdir -p /Users/u1149259/tools/extern/dingzhi
cd /Users/u1149259/tools/extern/dingzhi
git init -b main
```

- [ ] **Step 2: Gitignore dingzhi from the parent repo**

Append to `/Users/u1149259/tools/.gitignore`:

```
# dingzhi is a nested repository with its own history
extern/dingzhi/
```

- [ ] **Step 3: Create `.gitignore`, `version`, and `README.md`**

`extern/dingzhi/.gitignore`:

```
.DS_Store
*.backup.*
```

`extern/dingzhi/version`:

```
0.1.0
```

`extern/dingzhi/README.md`:

```markdown
# dingzhi

Turn a fresh macOS or Linux machine into a fully configured terminal
development environment with one command.

```bash
curl -fsSL https://raw.githubusercontent.com/chongchonghe/dingzhi/main/boot.sh | bash
```

Status: under development. See `docs/` in the parent repository for the design.
```

- [ ] **Step 4: Write the Dockerfile**

Ubuntu 24.04 with two build args: `WITH_SUDO` (1 = apt backend, 0 = eget+pixi
no-root) and `WITH_DEV_TOOLS` (1 = include the agentic-coding toolkit). The
toolkit is ssh, git-lfs, gh, gnupg, rsync, wget, build-essential, pkg-config,
python3-pip/venv, man-db, tree, htop, nano, file, iputils-ping, dnsutils, zip —
chosen so that nothing except `gh` overlaps dingzhi's own 34 apps. A
preinstalled app would make its installer's test pass vacuously.

`gh` is the one deliberate exception, because an agent working in the container
needs it. The `dingzhi-clean` variant (`WITH_DEV_TOOLS=0`) exists to test the
`github-cli` installer honestly.

The image also installs the Claude Code CLI via npm as the unprivileged user,
and creates `~/.ssh` with mode 700. The working tree is mounted at run time
rather than copied, so edits never require a rebuild.

**This file already exists and is verified:** `extern/dingzhi/tests/Dockerfile`.
All three images build and pass the smoke suite. Read it rather than rewriting
it.

- [ ] **Step 5: Write the build and run scripts**

**Both already exist and are verified:** `extern/dingzhi/tests/docker-build.sh`
and `extern/dingzhi/tests/docker-run.sh`.

`docker-build.sh [sudo|nosudo|clean|both|all]` builds the variants.

`docker-run.sh` mounts the working tree at `~/dingzhi` and nothing else — the
tree already carries `docs/` (design and plan) and `inbox/` (the configs and
scripts the porting tasks copy from). It selects the image with
`--nosudo` / `--clean`, allocates a TTY only when stdin actually is one (so it
works from scripts), and can forward credentials with `--with-claude-auth`,
`--ssh`, and `--gh-auth`. Each of those hands something private to whatever runs
in the container, so all three are opt-in.

- [ ] **Step 6: Write the bats helper**

`extern/dingzhi/tests/helpers.bash`:

```bash
# Shared setup for every dingzhi bats test.
#
# CRITICAL: this points HOME at a throwaway directory. No test may ever run
# without calling setup_dingzhi_env first.

setup_dingzhi_env() {
    DINGZHI_PATH="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
    export DINGZHI_PATH
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    cd "$HOME"
}
```

- [ ] **Step 7: Write the failing smoke test**

`extern/dingzhi/tests/unit/smoke.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "HOME is redirected away from the real home" {
    [ "$HOME" != "/home/dev" ]
    [ "$HOME" != "/root" ]
    [ -d "$HOME" ]
}

@test "DINGZHI_PATH points at the repository root" {
    [ -f "$DINGZHI_PATH/version" ]
}

@test "version file contains a semver string" {
    run cat "$DINGZHI_PATH/version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "the container has the Claude Code CLI" {
    run claude --version
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 8: Build the images and run the tests**

```bash
cd /Users/u1149259/tools/extern/dingzhi
tests/docker-build.sh both
tests/docker-run.sh -- bash -c 'bats tests/unit'
tests/docker-run.sh --nosudo -- bash -c 'bats tests/unit'
```

Expected: 7 tests pass in both containers (one skips on dingzhi-clean). Also confirm Claude Code is present:

```bash
tests/docker-run.sh -- bash -c 'claude --version'
```

Expected: a version string, exit 0.

- [ ] **Step 9: Confirm the nosudo image really cannot escalate**

```bash
tests/docker-run.sh --nosudo -- bash -c 'sudo -n true; echo "exit=$?"'
```

Expected: non-zero exit printed. If it prints `exit=0`, the `WITH_SUDO=0` branch is broken and Task 2's `noroot` detection will never be exercised.

- [ ] **Step 10: Write `start-in-docker.md`**

Orientation for a Claude Code session running inside the container: which image
it is in, where the plan is mounted, the seven working rules (bash 3.2, no
absolute paths, idempotency, tests never touch the real `$HOME`, dark theme
only, Conventional Commits), how to run the suite and the installer, how to
commit through the mount, and the two project-specific traps — preinstalled
`gh`, and symlinked configs receiving runtime state inside the checkout.

**Already exists and is verified:** `extern/dingzhi/start-in-docker.md`.

- [ ] **Step 11: Commit**

```bash
cd /Users/u1149259/tools/extern/dingzhi
git add -A
git commit -m "chore: repository skeleton and Docker test harness"

cd /Users/u1149259/tools
git add .gitignore
git commit -m "chore: ignore nested dingzhi repository"
```

---

### Task 2: `lib/detect.sh` — platform and backend detection

**Files:**
- Create: `extern/dingzhi/lib/detect.sh`
- Test: `extern/dingzhi/tests/unit/detect.bats`

**Interfaces:**
- Consumes: nothing
- Produces, after sourcing `lib/detect.sh`:
  - `DINGZHI_PATH` — absolute path to the repository root
  - `DINGZHI_OS` — `macos` or `linux`
  - `DINGZHI_BACKEND` — `brew`, `apt`, or `noroot`
  - `DINGZHI_BIN` — where binaries go: Homebrew prefix bin on macOS, `/usr/local/bin` under apt, `$HOME/local/bin` under noroot
  - `DINGZHI_ARCH` — `x86_64` or `arm64`
  - function `dingzhi_has_sudo()` — returns 0 if sudo is usable
  - Honors a pre-set `DINGZHI_BACKEND` (used by tests and by `--backend` overrides)

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/detect.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "detect sets DINGZHI_OS to linux in the container" {
    source "$DINGZHI_PATH/lib/detect.sh"
    [ "$DINGZHI_OS" = "linux" ]
}

@test "detect sets DINGZHI_ARCH to a known value" {
    source "$DINGZHI_PATH/lib/detect.sh"
    [[ "$DINGZHI_ARCH" == "x86_64" || "$DINGZHI_ARCH" == "arm64" ]]
}

@test "detect picks a valid backend" {
    source "$DINGZHI_PATH/lib/detect.sh"
    [[ "$DINGZHI_BACKEND" == "brew" || "$DINGZHI_BACKEND" == "apt" || "$DINGZHI_BACKEND" == "noroot" ]]
}

@test "an explicitly set backend is respected" {
    DINGZHI_BACKEND=noroot
    source "$DINGZHI_PATH/lib/detect.sh"
    [ "$DINGZHI_BACKEND" = "noroot" ]
}

@test "noroot backend points DINGZHI_BIN into HOME" {
    DINGZHI_BACKEND=noroot
    source "$DINGZHI_PATH/lib/detect.sh"
    [ "$DINGZHI_BIN" = "$HOME/local/bin" ]
}

@test "apt backend points DINGZHI_BIN at /usr/local/bin" {
    DINGZHI_BACKEND=apt
    source "$DINGZHI_PATH/lib/detect.sh"
    [ "$DINGZHI_BIN" = "/usr/local/bin" ]
}

@test "DINGZHI_PATH resolves to the repository root" {
    source "$DINGZHI_PATH/lib/detect.sh"
    [ -f "$DINGZHI_PATH/version" ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/detect.bats'
```

Expected: all 7 fail with "No such file or directory: lib/detect.sh".

- [ ] **Step 3: Write the implementation**

`extern/dingzhi/lib/detect.sh`:

```bash
#!/usr/bin/env bash
# Platform and backend detection. Sets variables only; installs nothing.
#
# Sets: DINGZHI_PATH DINGZHI_OS DINGZHI_ARCH DINGZHI_BACKEND DINGZHI_BIN
# Defines: dingzhi_has_sudo

# Repository root, derived from this file's location. Never hardcoded.
if [ -z "${DINGZHI_PATH:-}" ]; then
    DINGZHI_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
export DINGZHI_PATH

case "$(uname -s)" in
    Darwin) DINGZHI_OS=macos ;;
    Linux)  DINGZHI_OS=linux ;;
    *)      DINGZHI_OS=unsupported ;;
esac
export DINGZHI_OS

case "$(uname -m)" in
    x86_64|amd64)  DINGZHI_ARCH=x86_64 ;;
    arm64|aarch64) DINGZHI_ARCH=arm64 ;;
    *)             DINGZHI_ARCH="$(uname -m)" ;;
esac
export DINGZHI_ARCH

# True if sudo exists and we can actually use it without an interactive
# password. -n makes this non-blocking, which matters inside containers.
dingzhi_has_sudo() {
    command -v sudo >/dev/null 2>&1 || return 1
    sudo -n true >/dev/null 2>&1
}

# True on Debian, Ubuntu, and derivatives.
dingzhi_is_debian_family() {
    [ -r /etc/os-release ] || return 1
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}:${ID_LIKE:-}" in
        *debian*|*ubuntu*) return 0 ;;
        *) return 1 ;;
    esac
}

# Respect a caller-supplied backend (tests, --backend flag); otherwise detect.
if [ -z "${DINGZHI_BACKEND:-}" ]; then
    if [ "$DINGZHI_OS" = "macos" ]; then
        DINGZHI_BACKEND=brew
    elif dingzhi_is_debian_family && dingzhi_has_sudo; then
        DINGZHI_BACKEND=apt
    else
        DINGZHI_BACKEND=noroot
    fi
fi
export DINGZHI_BACKEND

case "$DINGZHI_BACKEND" in
    brew)
        if [ -x /opt/homebrew/bin/brew ]; then
            DINGZHI_BIN=/opt/homebrew/bin
        else
            DINGZHI_BIN=/usr/local/bin
        fi
        ;;
    apt)    DINGZHI_BIN=/usr/local/bin ;;
    noroot) DINGZHI_BIN="$HOME/local/bin" ;;
esac
export DINGZHI_BIN
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/detect.bats'
tests/docker-run.sh --nosudo -- bash -c 'bats tests/unit/detect.bats'
```

Expected: 7 pass in each. Then verify detection differs between the images:

```bash
tests/docker-run.sh -- bash -c 'source lib/detect.sh && echo $DINGZHI_BACKEND'
tests/docker-run.sh --nosudo -- bash -c 'source lib/detect.sh && echo $DINGZHI_BACKEND'
```

Expected: `apt` and `noroot` respectively. If both print the same value, detection is broken.

- [ ] **Step 5: Commit**

```bash
git add lib/detect.sh tests/unit/detect.bats
git commit -m "feat: platform and backend detection"
```

---

### Task 3: `lib/ui.sh` — output and prompts

Written before `pkg.sh` because every other library uses `say`/`warn`/`die`.

**Files:**
- Create: `extern/dingzhi/lib/ui.sh`
- Test: `extern/dingzhi/tests/unit/ui.bats`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `say <msg>` — informational line to stdout, prefixed `==>`
  - `step <msg>` — indented sub-line to stdout, prefixed `    `
  - `warn <msg>` — to stderr, prefixed `!! `
  - `die <msg>` — to stderr, prefixed `!! `, then `exit 1`
  - `skip <msg>` — indented, prefixed `    [skip] ` (the idempotency message)
  - `choose_multi <header> <default_csv> <item>...` — prints selected items one per line; uses `gum choose --no-limit` when available, otherwise returns the defaults unchanged
  - `prompt <question> <default>` — prints the answer; uses `gum input` when available, otherwise `read -r`; returns the default when `DINGZHI_NONINTERACTIVE=1`
  - `confirm <question>` — returns 0 for yes, 1 for no; returns 0 when `DINGZHI_NONINTERACTIVE=1`

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/ui.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
    source "$DINGZHI_PATH/lib/ui.sh"
}

@test "say writes to stdout with a prefix" {
    run say "hello"
    [ "$status" -eq 0 ]
    [ "$output" = "==> hello" ]
}

@test "skip writes an indented skip marker" {
    run skip "already there"
    [ "$status" -eq 0 ]
    [ "$output" = "    [skip] already there" ]
}

@test "warn writes to stderr" {
    run bash -c "source '$DINGZHI_PATH/lib/ui.sh'; warn oops 2>&1 1>/dev/null"
    [ "$output" = "!! oops" ]
}

@test "die exits non-zero" {
    run bash -c "source '$DINGZHI_PATH/lib/ui.sh'; die 'fatal'"
    [ "$status" -eq 1 ]
}

@test "prompt returns the default when non-interactive" {
    DINGZHI_NONINTERACTIVE=1
    run prompt "Your name" "Nobody"
    [ "$status" -eq 0 ]
    [ "$output" = "Nobody" ]
}

@test "confirm succeeds when non-interactive" {
    DINGZHI_NONINTERACTIVE=1
    run confirm "Proceed?"
    [ "$status" -eq 0 ]
}

@test "choose_multi returns defaults when non-interactive" {
    DINGZHI_NONINTERACTIVE=1
    run choose_multi "Pick" "core,git" core terminal git
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "core" ]
    [ "${lines[1]}" = "git" ]
    [ "${#lines[@]}" -eq 2 ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/ui.bats'
```

Expected: all fail, `lib/ui.sh` not found.

- [ ] **Step 3: Write the implementation**

`extern/dingzhi/lib/ui.sh`:

```bash
#!/usr/bin/env bash
# Output and prompt helpers. Prints and asks; never installs or writes config.
#
# Set DINGZHI_NONINTERACTIVE=1 to accept every default without prompting.

say()  { printf '==> %s\n' "$*"; }
step() { printf '    %s\n' "$*"; }
skip() { printf '    [skip] %s\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }
die()  { printf '!! %s\n' "$*" >&2; exit 1; }

_have_gum() { command -v gum >/dev/null 2>&1; }

# choose_multi <header> <default_csv> <item>...
# Prints the selected items, one per line.
choose_multi() {
    local header="$1" defaults="$2"
    shift 2

    if [ "${DINGZHI_NONINTERACTIVE:-0}" = "1" ] || ! _have_gum; then
        # Emit the defaults in the order the items were declared, keeping only
        # those that are actually offered.
        local item
        for item in "$@"; do
            case ",$defaults," in
                *",$item,"*) printf '%s\n' "$item" ;;
            esac
        done
        return 0
    fi

    gum choose "$@" \
        --no-limit \
        --selected "$defaults" \
        --height "$(( $# + 2 ))" \
        --header "$header"
}

# prompt <question> <default>
# Prints the answer.
prompt() {
    local question="$1" default="$2" answer

    if [ "${DINGZHI_NONINTERACTIVE:-0}" = "1" ]; then
        printf '%s\n' "$default"
        return 0
    fi

    if _have_gum; then
        answer="$(gum input --placeholder "$default" --prompt "$question: ")"
    else
        printf '%s [%s]: ' "$question" "$default" >&2
        read -r answer
    fi

    [ -n "$answer" ] || answer="$default"
    printf '%s\n' "$answer"
}

# confirm <question> -> 0 for yes, 1 for no
confirm() {
    local question="$1" answer

    [ "${DINGZHI_NONINTERACTIVE:-0}" = "1" ] && return 0

    if _have_gum; then
        gum confirm "$question"
        return $?
    fi

    printf '%s [y/N]: ' "$question" >&2
    read -r answer
    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/ui.bats'
```

Expected: 7 pass.

- [ ] **Step 5: Commit**

```bash
git add lib/ui.sh tests/unit/ui.bats
git commit -m "feat: output and prompt helpers"
```

---

### Task 4: `lib/pkg.sh` — the package abstraction

The core of the design. One table, three backends.

**Files:**
- Create: `extern/dingzhi/lib/pkg.sh`
- Test: `extern/dingzhi/tests/unit/pkg.bats`

**Interfaces:**
- Consumes: `DINGZHI_BACKEND`, `DINGZHI_BIN` from `lib/detect.sh`; `say`/`step`/`skip`/`warn`/`die` from `lib/ui.sh`
- Produces:
  - `pkg_resolve <generic> <backend>` — prints the backend-specific spec, or the empty string if the package has no mapping for that backend. Format per backend: `brew` → formula name; `apt` → apt package name; `noroot` → either `eget:<owner>/<repo>[|<asset-filter>[|<file-path>]]` or `pixi:<conda-package>` or `uv:<pypi-package>`
  - `pkg_binary <generic>` — prints the command name the package provides (usually the generic name; differs for `poppler` → `pdftotext`, `webp` → `cwebp`, `git-delta` → `delta`, `github-cli` → `gh`)
  - `pkg_installed <generic>` — returns 0 if `pkg_binary` is on `PATH`
  - `pkg_install <generic>` — installs if absent, prints a skip line if present, returns non-zero on failure
  - `pkg_remove <generic>` — uninstalls via the active backend

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/pkg.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
    source "$DINGZHI_PATH/lib/ui.sh"
}

@test "resolve fd for brew" {
    export DINGZHI_BACKEND=brew
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_resolve fd brew
    [ "$output" = "fd" ]
}

@test "resolve fd for apt uses the Debian package name" {
    export DINGZHI_BACKEND=apt
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_resolve fd apt
    [ "$output" = "fd-find" ]
}

@test "resolve fd for noroot uses an eget spec" {
    export DINGZHI_BACKEND=noroot
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_resolve fd noroot
    [[ "$output" == eget:sharkdp/fd* ]]
}

@test "resolve tmux for noroot uses pixi" {
    export DINGZHI_BACKEND=noroot
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_resolve tmux noroot
    [[ "$output" == pixi:* ]]
}

@test "resolve an unknown package returns empty" {
    export DINGZHI_BACKEND=apt
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_resolve definitely-not-a-package apt
    [ "$output" = "" ]
}

@test "pkg_binary maps poppler to pdftotext" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_binary poppler
    [ "$output" = "pdftotext" ]
}

@test "pkg_binary maps tlrc to tldr" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_binary tlrc
    [ "$output" = "tldr" ]
}

@test "pkg_binary maps git-delta to delta" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_binary git-delta
    [ "$output" = "delta" ]
}

@test "pkg_binary defaults to the generic name" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_binary fzf
    [ "$output" = "fzf" ]
}

@test "pkg_installed is true for a command that exists" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_installed git
    [ "$status" -eq 0 ]
}

@test "pkg_installed is false for a command that does not exist" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_installed lazygit
    [ "$status" -ne 0 ]
}

@test "every app directory has a resolvable package or an install script" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    # Guards against typos between the table and the app directory names.
    for d in "$DINGZHI_PATH"/apps/*/; do
        name="$(basename "$d")"
        [ -f "$d/install.sh" ] || { echo "missing install.sh for $name"; return 1; }
    done
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/pkg.bats'
```

Expected: all fail, `lib/pkg.sh` not found. (The final test will pass trivially until Task 8 creates app directories — that is fine.)

- [ ] **Step 3: Write the implementation**

`extern/dingzhi/lib/pkg.sh`:

```bash
#!/usr/bin/env bash
# Package abstraction over three backends: brew, apt, and eget+pixi (noroot).
#
# Requires lib/detect.sh and lib/ui.sh to be sourced first.
#
# The table below is the single place a package's per-platform identity lives.
# bash 3.2 has no associative arrays, so it is a case statement.
#
# noroot spec formats:
#   eget:<owner>/<repo>[|<asset-filter>[|<file-in-archive>]]
#   pixi:<conda-forge-package>
#   uv:<pypi-package>

# pkg_resolve <generic> <backend> -> backend-specific spec, or empty
pkg_resolve() {
    local name="$1" backend="$2"
    case "$name:$backend" in
        # ---- core CLI ----
        bat:brew)            echo "bat" ;;
        bat:apt)             echo "bat" ;;
        bat:noroot)          echo "eget:sharkdp/bat|x86_64-unknown-linux-gnu.tar.gz" ;;

        eza:brew)            echo "eza" ;;
        eza:apt)             echo "eza" ;;
        eza:noroot)          echo "eget:eza-community/eza|x86_64-unknown-linux-musl.tar.gz" ;;

        fd:brew)             echo "fd" ;;
        fd:apt)              echo "fd-find" ;;
        fd:noroot)           echo "eget:sharkdp/fd|x86_64-unknown-linux-gnu.tar.gz" ;;

        fzf:brew)            echo "fzf" ;;
        fzf:apt)             echo "fzf" ;;
        fzf:noroot)          echo "eget:junegunn/fzf|linux_amd64.tar.gz" ;;

        ripgrep:brew)        echo "ripgrep" ;;
        ripgrep:apt)         echo "ripgrep" ;;
        ripgrep:noroot)      echo "eget:BurntSushi/ripgrep|x86_64-unknown-linux-musl.tar.gz" ;;

        zoxide:brew)         echo "zoxide" ;;
        zoxide:apt)          echo "zoxide" ;;
        zoxide:noroot)       echo "eget:ajeetdsouza/zoxide|x86_64-unknown-linux-musl.tar.gz" ;;

        git-delta:brew)      echo "git-delta" ;;
        git-delta:apt)       echo "git-delta" ;;
        git-delta:noroot)    echo "eget:dandavison/delta|x86_64-unknown-linux-musl.tar.gz" ;;

        jq:brew)             echo "jq" ;;
        jq:apt)              echo "jq" ;;
        jq:noroot)           echo "eget:jqlang/jq|linux-amd64" ;;

        tlrc:brew)           echo "tlrc" ;;
        tlrc:apt)            echo "" ;;   # not packaged; handled by app script
        tlrc:noroot)         echo "eget:tldr-pages/tlrc|x86_64-unknown-linux-musl.tar.gz" ;;

        trash-cli:brew)      echo "trash-cli" ;;
        trash-cli:apt)       echo "trash-cli" ;;
        trash-cli:noroot)    echo "uv:trash-cli" ;;

        stow:brew)           echo "stow" ;;
        stow:apt)            echo "stow" ;;
        stow:noroot)         echo "pixi:stow" ;;

        thefuck:brew)        echo "thefuck" ;;
        thefuck:apt)         echo "uv:thefuck" ;;
        thefuck:noroot)      echo "uv:thefuck" ;;

        highlight:brew)      echo "highlight" ;;
        highlight:apt)       echo "highlight" ;;
        highlight:noroot)    echo "pixi:highlight" ;;

        # ---- terminal ----
        tmux:brew)           echo "tmux" ;;
        tmux:apt)            echo "tmux" ;;
        tmux:noroot)         echo "pixi:tmux==3.4" ;;

        # ---- editors ----
        neovim:brew)         echo "neovim" ;;
        # Ubuntu 24.04 ships nvim 0.9; the config needs 0.10+, so use eget there too.
        neovim:apt)          echo "" ;;
        neovim:noroot)       echo "eget:neovim/neovim|nvim-linux-x86_64.tar.gz|nvim-linux-x86_64/bin/nvim" ;;

        vim:brew)            echo "vim" ;;
        vim:apt)             echo "vim" ;;
        vim:noroot)          echo "pixi:vim" ;;

        # ---- git ----
        git:brew)            echo "git" ;;
        git:apt)             echo "git" ;;
        git:noroot)          echo "pixi:git" ;;

        lazygit:brew)        echo "lazygit" ;;
        lazygit:apt)         echo "" ;;   # not in Ubuntu repos
        lazygit:noroot)      echo "eget:jesseduffield/lazygit|Linux_x86_64.tar.gz" ;;

        github-cli:brew)     echo "gh" ;;
        github-cli:apt)      echo "" ;;   # needs a third-party apt repo
        github-cli:noroot)   echo "eget:cli/cli|linux_amd64.tar.gz|gh_*/bin/gh" ;;

        # ---- file managers ----
        yazi:brew)           echo "yazi" ;;
        yazi:apt)            echo "" ;;
        yazi:noroot)         echo "eget:sxyazi/yazi|x86_64-unknown-linux-musl.zip|yazi-x86_64-unknown-linux-musl/yazi" ;;

        vifm:brew)           echo "vifm" ;;
        vifm:apt)            echo "vifm" ;;
        vifm:noroot)         echo "pixi:vifm" ;;

        # ---- shell ----
        zsh:brew)            echo "zsh" ;;
        zsh:apt)             echo "zsh" ;;
        zsh:noroot)          echo "pixi:zsh" ;;

        # ---- dev ----
        cmake:brew)          echo "cmake" ;;
        cmake:apt)           echo "cmake" ;;
        cmake:noroot)        echo "pixi:cmake" ;;

        # ---- media ----
        pandoc:brew)         echo "pandoc" ;;
        pandoc:apt)          echo "pandoc" ;;
        pandoc:noroot)       echo "pixi:pandoc" ;;

        poppler:brew)        echo "poppler" ;;
        poppler:apt)         echo "poppler-utils" ;;
        poppler:noroot)      echo "pixi:poppler" ;;

        imagemagick:brew)    echo "imagemagick" ;;
        imagemagick:apt)     echo "imagemagick" ;;
        imagemagick:noroot)  echo "pixi:imagemagick" ;;

        ffmpeg:brew)         echo "ffmpeg" ;;
        ffmpeg:apt)          echo "ffmpeg" ;;
        ffmpeg:noroot)       echo "pixi:ffmpeg" ;;

        pngquant:brew)       echo "pngquant" ;;
        pngquant:apt)        echo "pngquant" ;;
        pngquant:noroot)     echo "pixi:pngquant" ;;

        jpegoptim:brew)      echo "jpegoptim" ;;
        jpegoptim:apt)       echo "jpegoptim" ;;
        jpegoptim:noroot)    echo "pixi:jpegoptim" ;;

        webp:brew)           echo "webp" ;;
        webp:apt)            echo "webp" ;;
        webp:noroot)         echo "pixi:libwebp-tools" ;;

        *) echo "" ;;
    esac
}

# pkg_binary <generic> -> the command the package provides
pkg_binary() {
    case "$1" in
        git-delta)   echo "delta" ;;
        github-cli)  echo "gh" ;;
        poppler)     echo "pdftotext" ;;
        webp)        echo "cwebp" ;;
        imagemagick) echo "magick" ;;
        trash-cli)   echo "trash-put" ;;
        tlrc)        echo "tldr" ;;
        *)           echo "$1" ;;
    esac
}

pkg_installed() {
    command -v "$(pkg_binary "$1")" >/dev/null 2>&1
}

# Install one package via the active backend. Idempotent.
pkg_install() {
    local name="$1" spec

    if pkg_installed "$name"; then
        skip "$name already installed"
        return 0
    fi

    spec="$(pkg_resolve "$name" "$DINGZHI_BACKEND")"
    if [ -z "$spec" ]; then
        warn "no $DINGZHI_BACKEND mapping for '$name'; the app script must handle it"
        return 1
    fi

    step "installing $name ($spec)"
    case "$DINGZHI_BACKEND" in
        brew)   brew install "$spec" ;;
        apt)    sudo apt-get install -y "$spec" ;;
        noroot) _pkg_install_noroot "$spec" ;;
    esac
}

_pkg_install_noroot() {
    local spec="$1" kind payload repo filter file

    kind="${spec%%:*}"
    payload="${spec#*:}"

    case "$kind" in
        pixi)
            pixi global install "$payload"
            ;;
        uv)
            uv tool install "$payload"
            ;;
        eget)
            # payload is repo[|filter[|file]]
            repo="${payload%%|*}"
            filter=""
            file=""
            if [ "$payload" != "$repo" ]; then
                local rest="${payload#*|}"
                filter="${rest%%|*}"
                [ "$rest" != "$filter" ] && file="${rest#*|}"
            fi
            mkdir -p "$DINGZHI_BIN"
            local args
            args="--to $DINGZHI_BIN"
            [ -n "$filter" ] && args="$args --asset $filter"
            [ -n "$file" ] && args="$args --file $file"
            # shellcheck disable=SC2086
            eget "$repo" $args
            ;;
        *)
            warn "unknown noroot spec kind: $kind"
            return 1
            ;;
    esac
}

pkg_remove() {
    local name="$1" spec kind payload
    spec="$(pkg_resolve "$name" "$DINGZHI_BACKEND")"
    [ -n "$spec" ] || { warn "no $DINGZHI_BACKEND mapping for '$name'"; return 1; }

    step "removing $name"
    case "$DINGZHI_BACKEND" in
        brew)   brew uninstall "$spec" ;;
        apt)    sudo apt-get remove -y "$spec" ;;
        noroot)
            kind="${spec%%:*}"
            payload="${spec#*:}"
            case "$kind" in
                pixi) pixi global uninstall "${payload%%==*}" ;;
                uv)   uv tool uninstall "$payload" ;;
                eget) rm -f "$DINGZHI_BIN/$(pkg_binary "$name")" ;;
            esac
            ;;
    esac
}
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/pkg.bats'
```

Expected: 12 pass.

- [ ] **Step 5: Verify a real install works on both backends**

```bash
tests/docker-run.sh -- bash -c '
  source lib/detect.sh && source lib/ui.sh && source lib/pkg.sh
  sudo apt-get update -qq
  pkg_install jq && jq --version && pkg_install jq'
```

Expected: installs, prints a version, then prints `[skip] jq already installed` on the second call.

- [ ] **Step 6: Commit**

```bash
git add lib/pkg.sh tests/unit/pkg.bats
git commit -m "feat: package abstraction over brew, apt, and eget+pixi"
```

---

### Task 5: `lib/link.sh` — symlink management

Ported from `~/tools/dotfiles/setup.sh`, keeping the backup-and-report behavior.

**Files:**
- Create: `extern/dingzhi/lib/link.sh`
- Test: `extern/dingzhi/tests/unit/link.bats`

**Interfaces:**
- Consumes: `say`/`step`/`skip`/`warn` from `lib/ui.sh`
- Produces:
  - `manage_symlink <src> <dest> <description>` — creates the link, backing up any real file at `dest` to `<dest>.backup.<timestamp>`; no-op when already correct
  - `unlink_managed <dest> <description>` — removes `dest` if and only if it is a symlink
  - `link_summary` — prints what was skipped and what was backed up during this run
  - `inject_line <file> <marker> <line> <label>` — appends `line` to `file` unless `marker` already appears in it

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/link.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
    source "$DINGZHI_PATH/lib/ui.sh"
    source "$DINGZHI_PATH/lib/link.sh"
    mkdir -p "$HOME/src"
    echo "content" > "$HOME/src/file"
}

@test "creates a symlink where nothing exists" {
    manage_symlink "$HOME/src/file" "$HOME/dest" "test file"
    [ -L "$HOME/dest" ]
    [ "$(cat "$HOME/dest")" = "content" ]
}

@test "creates missing parent directories" {
    manage_symlink "$HOME/src/file" "$HOME/a/b/c/dest" "nested"
    [ -L "$HOME/a/b/c/dest" ]
}

@test "is a no-op when the correct link already exists" {
    manage_symlink "$HOME/src/file" "$HOME/dest" "test file"
    run manage_symlink "$HOME/src/file" "$HOME/dest" "test file"
    [ "$status" -eq 0 ]
    [[ "$output" == *"already linked"* ]]
}

@test "backs up a real file instead of destroying it" {
    echo "precious" > "$HOME/dest"
    manage_symlink "$HOME/src/file" "$HOME/dest" "test file"
    [ -L "$HOME/dest" ]
    run bash -c "cat '$HOME'/dest.backup.*"
    [ "$output" = "precious" ]
}

@test "replaces a symlink pointing somewhere else" {
    echo "other" > "$HOME/src/other"
    ln -s "$HOME/src/other" "$HOME/dest"
    manage_symlink "$HOME/src/file" "$HOME/dest" "test file"
    [ "$(cat "$HOME/dest")" = "content" ]
}

@test "unlink_managed removes a symlink" {
    manage_symlink "$HOME/src/file" "$HOME/dest" "test file"
    unlink_managed "$HOME/dest" "test file"
    [ ! -e "$HOME/dest" ]
}

@test "unlink_managed refuses to remove a real file" {
    echo "precious" > "$HOME/dest"
    unlink_managed "$HOME/dest" "test file"
    [ -f "$HOME/dest" ]
    [ "$(cat "$HOME/dest")" = "precious" ]
}

@test "inject_line appends when the marker is absent" {
    touch "$HOME/.zshrc"
    inject_line "$HOME/.zshrc" "dingzhi/configs/shell" 'source /x/init.sh' "~/.zshrc"
    grep -q 'source /x/init.sh' "$HOME/.zshrc"
}

@test "inject_line is a no-op when the marker is present" {
    printf 'source /x/dingzhi/configs/shell/init.sh\n' > "$HOME/.zshrc"
    inject_line "$HOME/.zshrc" "dingzhi/configs/shell" 'source /y/init.sh' "~/.zshrc"
    run grep -c 'source' "$HOME/.zshrc"
    [ "$output" = "1" ]
}

@test "inject_line creates the file when it does not exist" {
    inject_line "$HOME/.bashrc" "marker" 'line' "~/.bashrc"
    [ -f "$HOME/.bashrc" ]
    grep -q 'line' "$HOME/.bashrc"
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/link.bats'
```

Expected: all 10 fail.

- [ ] **Step 3: Write the implementation**

`extern/dingzhi/lib/link.sh`:

```bash
#!/usr/bin/env bash
# Symlink management. Creates and removes links; never installs packages.
#
# Requires lib/ui.sh.

DINGZHI_SKIPPED_LINKS=""
DINGZHI_BACKED_UP=""

# Resolve a path to its absolute form. macOS has no `readlink -f`.
_abspath() {
    local p="$1"
    if [ -d "$p" ]; then
        (cd "$p" && pwd)
    else
        printf '%s/%s\n' "$(cd "$(dirname "$p")" && pwd)" "$(basename "$p")"
    fi
}

# manage_symlink <src> <dest> <description>
manage_symlink() {
    local src="$1" dest="$2" desc="$3"
    local src_abs target current backup

    src_abs="$(_abspath "$src")"

    if [ -L "$dest" ]; then
        # Compare where the link points, not the link's own path. A relative
        # target is resolved against the link's directory.
        target="$(readlink "$dest")"
        case "$target" in
            /*) current="$target" ;;
            *)  current="$(cd "$(dirname "$dest")" && pwd)/$target" ;;
        esac
        if [ "$current" = "$src_abs" ]; then
            skip "$desc already linked"
            DINGZHI_SKIPPED_LINKS="$DINGZHI_SKIPPED_LINKS$dest
"
            return 0
        fi
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        step "backing up existing $desc to $(basename "$backup")"
        mv "$dest" "$backup"
        DINGZHI_BACKED_UP="$DINGZHI_BACKED_UP$dest -> $backup
"
    fi

    step "linking $desc"
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src_abs" "$dest"
}

# unlink_managed <dest> <description>
unlink_managed() {
    local dest="$1" desc="$2"
    if [ -L "$dest" ]; then
        step "removing $desc"
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        warn "not removing $dest ($desc): not a symlink"
    fi
}

link_summary() {
    [ -n "$DINGZHI_SKIPPED_LINKS$DINGZHI_BACKED_UP" ] || return 0
    say "Link summary"
    if [ -n "$DINGZHI_BACKED_UP" ]; then
        step "backed up:"
        printf '%s' "$DINGZHI_BACKED_UP" | while IFS= read -r l; do
            [ -n "$l" ] && printf '        %s\n' "$l"
        done
    fi
}

# inject_line <file> <marker> <line> <label>
inject_line() {
    local file="$1" marker="$2" line="$3" label="$4"

    [ -e "$file" ] || touch "$file"

    if grep -qF "$marker" "$file" 2>/dev/null; then
        skip "$label already configured"
        return 0
    fi

    printf '\n%s\n' "$line" >> "$file"
    step "$label configured"
}
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/link.bats'
```

Expected: 10 pass.

- [ ] **Step 5: Commit**

```bash
git add lib/link.sh tests/unit/link.bats
git commit -m "feat: symlink management with backups"
```

---

### Task 6: `install/check-system.sh` and `install/bootstrap.sh`

**Files:**
- Create: `extern/dingzhi/install/check-system.sh`
- Create: `extern/dingzhi/install/bootstrap.sh`
- Test: `extern/dingzhi/tests/unit/check-system.bats`

**Interfaces:**
- Consumes: everything from `lib/detect.sh`, `lib/ui.sh`, `lib/pkg.sh`
- Produces: after `bootstrap.sh` runs, the active backend's package manager and `gum` are on `PATH`. Both scripts are sourced, not executed, by `install.sh`.

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/check-system.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "check-system passes on linux" {
    run bash -c "
        source '$DINGZHI_PATH/lib/detect.sh'
        source '$DINGZHI_PATH/lib/ui.sh'
        source '$DINGZHI_PATH/install/check-system.sh'
    "
    [ "$status" -eq 0 ]
}

@test "check-system aborts on an unsupported OS" {
    run bash -c "
        source '$DINGZHI_PATH/lib/detect.sh'
        source '$DINGZHI_PATH/lib/ui.sh'
        DINGZHI_OS=unsupported
        source '$DINGZHI_PATH/install/check-system.sh'
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"not supported"* ]]
}

@test "check-system aborts when git is missing" {
    run bash -c "
        source '$DINGZHI_PATH/lib/detect.sh'
        source '$DINGZHI_PATH/lib/ui.sh'
        PATH=/nonexistent
        source '$DINGZHI_PATH/install/check-system.sh'
    "
    [ "$status" -ne 0 ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/check-system.bats'
```

Expected: 3 fail.

- [ ] **Step 3: Write `install/check-system.sh`**

```bash
#!/usr/bin/env bash
# Abort early, before anything is written, if this machine cannot be supported.
#
# Sourced by install.sh. Requires lib/detect.sh and lib/ui.sh.

if [ "$DINGZHI_OS" = "unsupported" ]; then
    die "$(uname -s) is not supported. dingzhi runs on macOS and Linux."
fi

for required in curl git; do
    command -v "$required" >/dev/null 2>&1 \
        || die "'$required' is required but not installed. Install it and re-run."
done

if [ "$DINGZHI_OS" = "linux" ] && [ "$DINGZHI_ARCH" != "x86_64" ]; then
    warn "Linux on $DINGZHI_ARCH is untested; the no-root binaries are x86_64-only."
fi

say "System check passed: $DINGZHI_OS/$DINGZHI_ARCH, backend=$DINGZHI_BACKEND"
```

- [ ] **Step 4: Write `install/bootstrap.sh`**

```bash
#!/usr/bin/env bash
# Install the package backend itself, then gum. Everything after this point
# may use the TUI.
#
# Sourced by install.sh. Requires lib/detect.sh, lib/ui.sh, lib/pkg.sh.

say "Bootstrapping the $DINGZHI_BACKEND backend"

case "$DINGZHI_BACKEND" in
    brew)
        if command -v brew >/dev/null 2>&1; then
            skip "Homebrew already installed"
        else
            step "installing Homebrew"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
        ;;

    apt)
        step "refreshing apt package lists"
        sudo apt-get update -qq
        ;;

    noroot)
        mkdir -p "$DINGZHI_BIN"
        export PATH="$DINGZHI_BIN:$HOME/.pixi/bin:$PATH"

        if command -v eget >/dev/null 2>&1; then
            skip "eget already installed"
        else
            step "installing eget"
            tmp="$(mktemp -d)"
            curl -sSL https://zyedidia.github.io/eget.sh -o "$tmp/eget.sh"
            ( cd "$tmp" && sh eget.sh && mv eget "$DINGZHI_BIN/" )
            rm -rf "$tmp"
        fi

        if command -v pixi >/dev/null 2>&1; then
            skip "pixi already installed"
        else
            step "installing pixi"
            curl -fsSL https://pixi.sh/install.sh | PIXI_NO_PATH_UPDATE=1 bash
            export PATH="$HOME/.pixi/bin:$PATH"
        fi
        ;;
esac

# uv is needed by the `uv:` specs in the package table, so it comes before gum.
if command -v uv >/dev/null 2>&1; then
    skip "uv already installed"
else
    step "installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
    export PATH="$HOME/.local/bin:$PATH"
fi

if command -v gum >/dev/null 2>&1; then
    skip "gum already installed"
else
    step "installing gum"
    case "$DINGZHI_BACKEND" in
        brew) brew install gum ;;
        apt|noroot)
            # gum is not in Ubuntu's repos; take the release binary either way.
            mkdir -p "$DINGZHI_BIN"
            if [ "$DINGZHI_BACKEND" = "apt" ]; then
                tmp="$(mktemp -d)"
                curl -sSL https://zyedidia.github.io/eget.sh -o "$tmp/eget.sh"
                ( cd "$tmp" && sh eget.sh && sudo mv eget "$DINGZHI_BIN/" )
                rm -rf "$tmp"
                sudo "$DINGZHI_BIN/eget" charmbracelet/gum \
                    --asset "Linux_x86_64.tar.gz" --to "$DINGZHI_BIN"
            else
                eget charmbracelet/gum --asset "Linux_x86_64.tar.gz" --to "$DINGZHI_BIN"
            fi
            ;;
    esac
fi

command -v gum >/dev/null 2>&1 \
    || warn "gum unavailable; falling back to plain-text prompts"
```

- [ ] **Step 5: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/check-system.bats'
```

Expected: 3 pass.

- [ ] **Step 6: Verify bootstrap works on both backends**

```bash
tests/docker-run.sh -- bash -c '
  set -e
  source lib/detect.sh; source lib/ui.sh; source lib/pkg.sh
  source install/check-system.sh; source install/bootstrap.sh
  gum --version && uv --version'

tests/docker-run.sh --nosudo -- bash -c '
  set -e
  source lib/detect.sh; source lib/ui.sh; source lib/pkg.sh
  source install/check-system.sh; source install/bootstrap.sh
  gum --version && uv --version && eget --version && pixi --version'
```

Expected: version strings, exit 0, in both.

- [ ] **Step 7: Commit**

```bash
git add install/check-system.sh install/bootstrap.sh tests/unit/check-system.bats
git commit -m "feat: system check and backend bootstrap"
```

---

### Task 7: `install/choices.sh` and `install/identification.sh`

**Files:**
- Create: `extern/dingzhi/install/choices.sh`
- Create: `extern/dingzhi/install/identification.sh`
- Test: `extern/dingzhi/tests/unit/choices.bats`

**Interfaces:**
- Consumes: `choose_multi`, `prompt` from `lib/ui.sh`
- Produces:
  - `DINGZHI_GROUPS` — space-separated selected group names
  - `DINGZHI_SHELLS` — space-separated, subset of `zsh bash`
  - State file `$DINGZHI_STATE/choices` (where `DINGZHI_STATE` is `${XDG_STATE_HOME:-$HOME/.local/state}/dingzhi`), containing `DINGZHI_GROUPS=` and `DINGZHI_SHELLS=` lines — prefixed because bash has a builtin `GROUPS` array that a bare `GROUPS=` would collide with; re-read on subsequent runs so re-installs are non-interactive
  - `~/.gitconfig.local` containing a `[user]` section

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/choices.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
    export DINGZHI_NONINTERACTIVE=1
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/ui.sh"
}

@test "non-interactive choices select every group" {
    source "$DINGZHI_PATH/install/choices.sh"
    for g in core terminal editors git filemanagers shell dev media misc; do
        [[ " $DINGZHI_GROUPS " == *" $g "* ]] || { echo "missing group: $g"; return 1; }
    done
}

@test "non-interactive choices default to zsh only" {
    source "$DINGZHI_PATH/install/choices.sh"
    [ "$DINGZHI_SHELLS" = "zsh" ]
}

@test "choices are persisted to the state file" {
    source "$DINGZHI_PATH/install/choices.sh"
    [ -f "$HOME/.local/state/dingzhi/choices" ]
    grep -q '^GROUPS=' "$HOME/.local/state/dingzhi/choices"
    grep -q '^SHELLS=' "$HOME/.local/state/dingzhi/choices"
}

@test "persisted choices are reused on the next run" {
    mkdir -p "$HOME/.local/state/dingzhi"
    printf 'GROUPS=core git\nSHELLS=bash\n' > "$HOME/.local/state/dingzhi/choices"
    source "$DINGZHI_PATH/install/choices.sh"
    [ "$DINGZHI_GROUPS" = "core git" ]
    [ "$DINGZHI_SHELLS" = "bash" ]
}

@test "identification writes a gitconfig.local" {
    DINGZHI_GIT_NAME="Test User" DINGZHI_GIT_EMAIL="test@example.com" \
        source "$DINGZHI_PATH/install/identification.sh"
    [ -f "$HOME/.gitconfig.local" ]
    grep -q 'name = Test User' "$HOME/.gitconfig.local"
    grep -q 'email = test@example.com' "$HOME/.gitconfig.local"
}

@test "identification does not overwrite an existing gitconfig.local" {
    printf '[user]\n\tname = Existing\n' > "$HOME/.gitconfig.local"
    DINGZHI_GIT_NAME="Test User" DINGZHI_GIT_EMAIL="test@example.com" \
        source "$DINGZHI_PATH/install/identification.sh"
    grep -q 'name = Existing' "$HOME/.gitconfig.local"
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/choices.bats'
```

Expected: 6 fail.

- [ ] **Step 3: Write `install/choices.sh`**

```bash
#!/usr/bin/env bash
# The only app-selection prompts dingzhi asks. Choices persist so that
# re-running the installer is non-interactive.
#
# Sets: DINGZHI_GROUPS DINGZHI_SHELLS DINGZHI_STATE
# Requires lib/ui.sh.

DINGZHI_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dingzhi"
export DINGZHI_STATE
mkdir -p "$DINGZHI_STATE"

DINGZHI_ALL_GROUPS="core terminal editors git filemanagers shell dev media misc"

if [ -f "$DINGZHI_STATE/choices" ]; then
    # shellcheck disable=SC1091
    . "$DINGZHI_STATE/choices"
    DINGZHI_GROUPS="$GROUPS"
    DINGZHI_SHELLS="$SHELLS"
    skip "using saved choices from $DINGZHI_STATE/choices"
else
    # shellcheck disable=SC2086
    DINGZHI_GROUPS="$(choose_multi \
        "Which app groups do you want?" \
        "core,terminal,editors,git,filemanagers,shell,dev,media,misc" \
        $DINGZHI_ALL_GROUPS | tr '\n' ' ')"
    DINGZHI_GROUPS="${DINGZHI_GROUPS% }"

    DINGZHI_SHELLS="$(choose_multi \
        "Which shells should dingzhi configure?" \
        "zsh" \
        zsh bash | tr '\n' ' ')"
    DINGZHI_SHELLS="${DINGZHI_SHELLS% }"

    printf 'GROUPS=%s\nSHELLS=%s\n' "$DINGZHI_GROUPS" "$DINGZHI_SHELLS" \
        > "$DINGZHI_STATE/choices"
fi

export DINGZHI_GROUPS DINGZHI_SHELLS
say "Groups: $DINGZHI_GROUPS"
say "Shells: $DINGZHI_SHELLS"
```

- [ ] **Step 4: Write `install/identification.sh`**

```bash
#!/usr/bin/env bash
# Collect git identity into ~/.gitconfig.local, which the shipped gitconfig
# includes. The shipped config never contains a name or email.
#
# Requires lib/ui.sh. Honors DINGZHI_GIT_NAME / DINGZHI_GIT_EMAIL for tests.

if [ -f "$HOME/.gitconfig.local" ]; then
    skip "~/.gitconfig.local already exists"
else
    _name="${DINGZHI_GIT_NAME:-$(prompt "Your name (for git commits)" "$(whoami)")}"
    _email="${DINGZHI_GIT_EMAIL:-$(prompt "Your email (for git commits)" "$(whoami)@localhost")}"

    cat > "$HOME/.gitconfig.local" <<EOF
# Local git identity, written by dingzhi. Not tracked by any repository.
[user]
	name = $_name
	email = $_email
EOF
    step "wrote ~/.gitconfig.local for $_name <$_email>"
    unset _name _email
fi
```

- [ ] **Step 5: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/choices.bats'
```

Expected: 6 pass.

- [ ] **Step 6: Commit**

```bash
git add install/choices.sh install/identification.sh tests/unit/choices.bats
git commit -m "feat: first-run choices and git identity"
```

---

### Task 8: `configs/shell/` — the shell configuration

Ported from `~/tools/dotfiles/shell/`, with personal content stripped.

**Files:**
- Create: `extern/dingzhi/configs/shell/init.sh`
- Create: `extern/dingzhi/configs/shell/env.sh`
- Create: `extern/dingzhi/configs/shell/aliases.sh`
- Create: `extern/dingzhi/configs/shell/functions.sh`
- Create: `extern/dingzhi/configs/shell/platform.sh`
- Create: `extern/dingzhi/configs/shell/mac.sh`
- Create: `extern/dingzhi/configs/shell/linux.sh`
- Test: `extern/dingzhi/tests/unit/shell-config.bats`

**Interfaces:**
- Consumes: nothing at install time; sourced by the user's `~/.zshrc` / `~/.bashrc` at shell startup
- Produces: `init.sh` as the single entry point. It derives `DINGZHI_PATH` from its own location and sources `env.sh`, `aliases.sh`, `functions.sh`, `platform.sh` in that order. Must be valid under both bash and zsh.

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/shell-config.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "init.sh sources cleanly under bash" {
    run bash -c "source '$DINGZHI_PATH/configs/shell/init.sh'; echo ok"
    [ "$status" -eq 0 ]
    [[ "$output" == *ok* ]]
}

@test "init.sh puts the dingzhi bin directory on PATH" {
    run bash -c "source '$DINGZHI_PATH/configs/shell/init.sh'; echo \$PATH"
    [[ "$output" == *"$DINGZHI_PATH/bin"* ]]
}

@test "init.sh defines the ll alias" {
    run bash -c "source '$DINGZHI_PATH/configs/shell/init.sh'; alias ll"
    [ "$status" -eq 0 ]
}

@test "no personal paths remain in the shell config" {
    run grep -rEl 'Users/(cche|u1149259)|HOME/tools|MOVE_ROOT|RC_HOME|quokka' \
        "$DINGZHI_PATH/configs/shell/"
    [ "$status" -ne 0 ]
}

@test "sourcing twice does not duplicate PATH entries" {
    run bash -c "
        source '$DINGZHI_PATH/configs/shell/init.sh'
        source '$DINGZHI_PATH/configs/shell/init.sh'
        echo \$PATH | tr ':' '\n' | grep -c '$DINGZHI_PATH/bin'
    "
    [ "$output" = "1" ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/shell-config.bats'
```

Expected: 5 fail.

- [ ] **Step 3: Write `configs/shell/env.sh`**

Ported from `~/tools/dotfiles/shell/core.env.sh` with `$HOME/tools/bin` replaced and the `RC_HOME` / `MOVE_*` exports dropped.

```bash
# shellcheck shell=bash
# PATH and shared environment. Sourced by init.sh.

_path_remove() {
    local target="$1" cleaned
    cleaned="$(printf '%s' "$PATH" | awk -v RS=':' -v ORS=':' -v t="$target" '$0 != "" && $0 != t {print}')"
    PATH="${cleaned%:}"
}

# Prepend, de-duplicating first so repeated sourcing is idempotent.
pathp() {
    if [ -d "$1" ]; then
        _path_remove "$1"
        export PATH="$1${PATH:+:$PATH}"
    fi
}

patha() {
    if [ -d "$1" ]; then
        _path_remove "$1"
        export PATH="${PATH:+$PATH:}$1"
    fi
}

pathp "$DINGZHI_PATH/bin"
pathp "$HOME/local/bin"
pathp "$HOME/.local/bin"
pathp "$HOME/.pixi/bin"

export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"
```

- [ ] **Step 4: Write `configs/shell/aliases.sh`**

Generic subset of `~/tools/dotfiles/shell/core.aliases.sh`.

```bash
# shellcheck shell=bash
# Shared aliases. Sourced by init.sh.

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --group-directories-first --git'
    alias la='eza -la --group-directories-first --git'
    alias lt='eza --tree --level=2'
else
    alias ll='ls -l'
    alias la='ls -la'
fi

command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
command -v batcat >/dev/null 2>&1 && alias bat='batcat'
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'
command -v nvim >/dev/null 2>&1 && alias vi='nvim' && alias vim='nvim'

alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
```

- [ ] **Step 5: Write `configs/shell/functions.sh`**

Generic subset of `~/tools/dotfiles/shell/core.functions.sh`.

```bash
# shellcheck shell=bash
# Shared functions. Sourced by init.sh.

# mkcd <dir> — create a directory and enter it.
mkcd() {
    [ -n "$1" ] || { echo "usage: mkcd <dir>" >&2; return 1; }
    mkdir -p "$1" && cd "$1" || return 1
}

# up [n] — go up n directories (default 1).
up() {
    local n="${1:-1}" path=""
    while [ "$n" -gt 0 ]; do
        path="../$path"
        n=$((n - 1))
    done
    cd "$path" || return 1
}

# extract <archive> — unpack any common archive format.
extract() {
    [ -f "$1" ] || { echo "extract: not a file: $1" >&2; return 1; }
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz)         tar xJf "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.zip)            unzip "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.7z)             7z x "$1" ;;
        *) echo "extract: unknown format: $1" >&2; return 1 ;;
    esac
}
```

- [ ] **Step 6: Write `configs/shell/platform.sh`, `mac.sh`, and `linux.sh`**

`platform.sh`:

```bash
# shellcheck shell=bash
# Dispatch to the platform-specific config. Sourced by init.sh.

case "$(uname -s)" in
    Darwin) . "$DINGZHI_PATH/configs/shell/mac.sh" ;;
    Linux)  . "$DINGZHI_PATH/configs/shell/linux.sh" ;;
esac
```

`mac.sh`:

```bash
# shellcheck shell=bash
# macOS-specific shell configuration.

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

alias o='open'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'
```

`linux.sh`:

```bash
# shellcheck shell=bash
# Linux-specific shell configuration.

command -v xdg-open >/dev/null 2>&1 && alias o='xdg-open'
alias free='free -h'
alias df='df -h'
```

- [ ] **Step 7: Write `configs/shell/init.sh`**

```bash
# shellcheck shell=bash
# dingzhi shell entry point. One line in ~/.zshrc or ~/.bashrc sources this.
#
# Must be valid under both bash and zsh. No bashisms zsh rejects, no zsh-isms
# bash rejects.

# Locate the dingzhi checkout from this file, under either shell.
if [ -n "${BASH_SOURCE[0]:-}" ]; then
    _dingzhi_self="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
    _dingzhi_self="${(%):-%N}"
else
    _dingzhi_self="$0"
fi
DINGZHI_PATH="$(cd "$(dirname "$_dingzhi_self")/../.." && pwd)"
export DINGZHI_PATH
unset _dingzhi_self

. "$DINGZHI_PATH/configs/shell/env.sh"
. "$DINGZHI_PATH/configs/shell/aliases.sh"
. "$DINGZHI_PATH/configs/shell/functions.sh"
. "$DINGZHI_PATH/configs/shell/platform.sh"

command -v zoxide >/dev/null 2>&1 && {
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(zoxide init zsh)"
    else
        eval "$(zoxide init bash)"
    fi
}
```

- [ ] **Step 8: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/shell-config.bats'
```

Expected: 5 pass.

- [ ] **Step 9: Commit**

```bash
git add configs/shell tests/unit/shell-config.bats
git commit -m "feat: shell configuration"
```

---

### Task 9: `configs/` and `themes/` — ported dotfiles

**Files:**
- Create: `extern/dingzhi/configs/git/gitconfig`
- Create: `extern/dingzhi/configs/git/gitignore_global`
- Create: `extern/dingzhi/themes/catppuccin/delta.gitconfig`
- Copy: `~/tools/dotfiles/{kitty,nvim,tmux,yazi,vifm,bat,lazygit,cheat}` → `extern/dingzhi/configs/`
- Test: `extern/dingzhi/tests/unit/configs.bats`

**Interfaces:**
- Consumes: nothing
- Produces: `configs/<app>/` trees that app install scripts symlink into place. `configs/git/gitconfig` has no `[user]` section and includes both `~/.gitconfig.local` and the vendored delta theme.

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/configs.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "gitconfig has no hardcoded user identity" {
    run grep -E '^\s*(name|email)\s*=' "$DINGZHI_PATH/configs/git/gitconfig"
    [ "$status" -ne 0 ]
}

@test "gitconfig includes gitconfig.local" {
    grep -q 'gitconfig.local' "$DINGZHI_PATH/configs/git/gitconfig"
}

@test "gitconfig does not reference a personal checkout path" {
    run grep -E 'git/catppuccin|Users/' "$DINGZHI_PATH/configs/git/gitconfig"
    [ "$status" -ne 0 ]
}

@test "the delta theme is vendored" {
    [ -f "$DINGZHI_PATH/themes/catppuccin/delta.gitconfig" ]
    grep -q 'catppuccin-mocha' "$DINGZHI_PATH/themes/catppuccin/delta.gitconfig"
}

@test "gitconfig is valid and readable by git" {
    run git config --file "$DINGZHI_PATH/configs/git/gitconfig" --list
    [ "$status" -eq 0 ]
}

@test "every expected config directory exists" {
    for d in kitty nvim tmux yazi vifm bat lazygit cheat git shell; do
        [ -d "$DINGZHI_PATH/configs/$d" ] || { echo "missing configs/$d"; return 1; }
    done
}

@test "no config file contains a personal absolute path" {
    run grep -rEl 'Users/(cche|u1149259)|/home/(cche|chong)' "$DINGZHI_PATH/configs/"
    [ "$status" -ne 0 ]
}

@test "no config selects a light theme" {
    run grep -rEil 'catppuccin[-_ ]?latte|darktheme' "$DINGZHI_PATH/configs/"
    [ "$status" -ne 0 ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/configs.bats'
```

Expected: 8 fail.

- [ ] **Step 3: Copy the config trees**

```bash
cd "$DINGZHI_PATH"
mkdir -p configs themes/catppuccin
for d in kitty nvim tmux yazi vifm bat lazygit cheat; do
    cp -R "inbox/dotfiles/$d" "configs/$d"
done
# Drop the personal and stale bits that came along for the ride.
rm -rf configs/kitty/sessions configs/kitty/trash configs/kitty/se \
       configs/kitty/t1 configs/kitty/kitty
find configs -name '.DS_Store' -delete
find configs -name '*.bk' -delete
find configs -name '*.backup.*' -delete
```

`inbox/` holds exactly the ten config directories and two scripts the spec
ships, copied out of the tools repo. If it is missing, this task cannot proceed
— say so rather than inventing configs.

Then read every remaining file and remove any absolute personal path, any Latte/light theme reference, and any `current-theme.conf` include left over from the toggle. `configs/kitty/kitty.conf` must `include default-theme.conf` and nothing else theme-related; `configs/tmux/tmux.conf` should be the macOS variant (`~/tools/dotfiles/tmux/tmux.conf`) and `configs/lazygit/config.yml` the full one — the `.minimal` variants existed for Linux only and dingzhi installs the same theme everywhere.

- [ ] **Step 4: Write `configs/git/gitconfig`**

Ported from `~/tools/dotfiles/git/.gitconfig`, identity removed, delta include repointed.

```ini
# dingzhi git configuration. Identity lives in ~/.gitconfig.local.

[include]
	path = ~/.gitconfig.local
	path = ~/.config/dingzhi-delta-theme.gitconfig

[pull]
	rebase = false

[push]
	autoSetupRemote = true

[init]
	defaultBranch = main

[alias]
	fa = fetch --all
	su = submodule update
	amend = commit --amend --no-edit
	cc = commit -m 'regular commit'

[core]
	pager = delta
	excludesfile = ~/.gitignore_global

[interactive]
	diffFilter = delta --color-only

[delta]
	navigate = true
	side-by-side = true
	line-numbers = true
	wrap-max-lines = unlimited
	dark = true
	features = catppuccin-mocha

[filter "lfs"]
	process = git-lfs filter-process
	required = true
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
```

Both `[include]` paths live in the single section at the top of the file:

```ini
[include]
	path = ~/.gitconfig.local
	path = ~/.config/dingzhi-delta-theme.gitconfig
```

Note: `width = 177` from the original is dropped — it hardcodes one monitor's width and delta defaults to the terminal width.

- [ ] **Step 5: Vendor the delta theme**

```bash
cd "$DINGZHI_PATH"
cp inbox/delta/catppuccin.gitconfig themes/catppuccin/delta.gitconfig
grep -q 'catppuccin-mocha' themes/catppuccin/delta.gitconfig
```

`inbox/delta/catppuccin.gitconfig` is a vendored copy of
`catppuccin/delta`'s `catppuccin.gitconfig`, so this works offline and does not
depend on the upstream URL still resolving.

- [ ] **Step 6: Copy the global gitignore**

```bash
cp inbox/dotfiles/git/.gitignore_global configs/git/gitignore_global
```

- [ ] **Step 7: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/configs.bats'
```

Expected: 8 pass. If "no personal absolute path" fails, it prints the offending files — fix each and re-run.

- [ ] **Step 8: Commit**

```bash
git add configs themes tests/unit/configs.bats
git commit -m "feat: ported dotfiles and vendored catppuccin theme"
```

---

### Task 10: App scripts — `core` group

**Files:**
- Create: `extern/dingzhi/apps/{bat,eza,fd,fzf,ripgrep,zoxide,git-delta,jq,tlrc,trash-cli,stow,thefuck,highlight}/install.sh`
- Test: `extern/dingzhi/tests/unit/apps-core.bats`

**Interfaces:**
- Consumes: `pkg_install`, `pkg_installed` from `lib/pkg.sh`; `manage_symlink` from `lib/link.sh`; `say`/`step`/`skip` from `lib/ui.sh`; `DINGZHI_PATH`, `DINGZHI_BACKEND`, `DINGZHI_BIN`
- Produces: each app script is *sourced* (not executed) by `install.sh` with the libraries already loaded. Each declares its group via a `# group: <name>` comment on line 2, which the app loop and the TUI parse.

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/apps-core.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

CORE_APPS="bat eza fd fzf ripgrep zoxide git-delta jq tlrc trash-cli stow thefuck highlight"

@test "every core app has an install script" {
    for a in $CORE_APPS; do
        [ -f "$DINGZHI_PATH/apps/$a/install.sh" ] || { echo "missing: $a"; return 1; }
    done
}

@test "every core app declares the core group" {
    for a in $CORE_APPS; do
        grep -q '^# group: core$' "$DINGZHI_PATH/apps/$a/install.sh" \
            || { echo "bad group header: $a"; return 1; }
    done
}

@test "every app script passes shellcheck" {
    for a in $CORE_APPS; do
        run shellcheck -s bash -e SC1091 "$DINGZHI_PATH/apps/$a/install.sh"
        [ "$status" -eq 0 ] || { echo "shellcheck failed: $a"; echo "$output"; return 1; }
    done
}

@test "no app script uses bash 4+ syntax" {
    run grep -rlE 'declare -A|mapfile|readarray|\$\{[A-Za-z_]+\^\^\}|\$\{[A-Za-z_]+,,\}' \
        "$DINGZHI_PATH/apps/"
    [ "$status" -ne 0 ]
}

@test "installing bat twice is idempotent" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/ui.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    source "$DINGZHI_PATH/lib/link.sh"
    sudo apt-get update -qq
    source "$DINGZHI_PATH/apps/bat/install.sh"
    run bash -c "
        source '$DINGZHI_PATH/lib/detect.sh'
        source '$DINGZHI_PATH/lib/ui.sh'
        source '$DINGZHI_PATH/lib/pkg.sh'
        source '$DINGZHI_PATH/lib/link.sh'
        source '$DINGZHI_PATH/apps/bat/install.sh'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"[skip]"* ]]
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/apps-core.bats'
```

Expected: 5 fail.

- [ ] **Step 3: Write the nine trivial app scripts**

Each is the same three lines with a different name. `apps/eza/install.sh`:

```bash
#!/usr/bin/env bash
# group: core
pkg_install eza
```

Repeat verbatim for `fzf`, `ripgrep`, `zoxide`, `jq`, `stow`, `thefuck`, `highlight`, `trash-cli`, substituting the app name in the `pkg_install` line. Nine files in total, all with `# group: core` on line 2.

- [ ] **Step 4: Write `apps/bat/install.sh`**

Debian names the binary `batcat`; the config directory differs from the binary name.

```bash
#!/usr/bin/env bash
# group: core
pkg_install bat

# Debian ships the binary as batcat. Provide a `bat` shim so configs and
# aliases can assume one name.
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    step "linked batcat -> ~/.local/bin/bat"
fi

manage_symlink "$DINGZHI_PATH/configs/bat" "$HOME/.config/bat" "bat config"
```

- [ ] **Step 5: Write `apps/fd/install.sh`**

```bash
#!/usr/bin/env bash
# group: core
pkg_install fd

# Debian ships the binary as fdfind.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    step "linked fdfind -> ~/.local/bin/fd"
fi
```

- [ ] **Step 6: Write `apps/git-delta/install.sh`**

```bash
#!/usr/bin/env bash
# group: core
pkg_install git-delta

# The shipped gitconfig includes this path; put the vendored theme there so
# the include resolves without pointing into the checkout.
manage_symlink "$DINGZHI_PATH/themes/catppuccin/delta.gitconfig" \
    "$HOME/.config/dingzhi-delta-theme.gitconfig" \
    "delta catppuccin theme"
```

- [ ] **Step 7: Write `apps/tlrc/install.sh`**

`tlrc` has no apt package, so fall back to the eget spec there.

```bash
#!/usr/bin/env bash
# group: core
if pkg_installed tlrc; then
    skip "tlrc already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    # Not packaged for Debian; take the release binary.
    step "installing tlrc from GitHub releases"
    sudo eget tldr-pages/tlrc \
        --asset "x86_64-unknown-linux-musl.tar.gz" --to "$DINGZHI_BIN"
else
    pkg_install tlrc
fi
```

- [ ] **Step 8: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/apps-core.bats'
```

Expected: 5 pass.

- [ ] **Step 9: Verify the whole group installs on both backends**

```bash
for img in "" "--nosudo"; do
  tests/docker-run.sh $img -- bash -c '
    set -e
    source lib/detect.sh; source lib/ui.sh; source lib/pkg.sh; source lib/link.sh
    source install/check-system.sh; source install/bootstrap.sh
    for a in bat eza fd fzf ripgrep zoxide git-delta jq tlrc trash-cli stow thefuck highlight; do
        source "apps/$a/install.sh"
    done
    for c in bat eza fd fzf rg zoxide delta jq tldr trash-put stow thefuck highlight; do
        command -v "$c" >/dev/null || { echo "MISSING: $c"; exit 1; }
    done
    echo "core group OK"'
done
```

Expected: `core group OK` from both.

- [ ] **Step 10: Commit**

```bash
git add apps tests/unit/apps-core.bats
git commit -m "feat: core CLI app installers"
```

---

### Task 11: App scripts — `terminal`, `editors`, `git`, `filemanagers` groups

**Files:**
- Create: `extern/dingzhi/apps/{kitty,tmux,neovim,vim,git,lazygit,github-cli,yazi,vifm}/install.sh`
- Test: `extern/dingzhi/tests/unit/apps-groups.bats`

**Interfaces:**
- Consumes: same as Task 10
- Produces: nine more app scripts, group headers `terminal`, `editors`, `git`, `filemanagers`

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/apps-groups.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "terminal group apps exist with the right header" {
    for a in kitty tmux; do
        grep -q '^# group: terminal$' "$DINGZHI_PATH/apps/$a/install.sh" \
            || { echo "bad: $a"; return 1; }
    done
}

@test "editors group apps exist with the right header" {
    for a in neovim vim; do
        grep -q '^# group: editors$' "$DINGZHI_PATH/apps/$a/install.sh" \
            || { echo "bad: $a"; return 1; }
    done
}

@test "git group apps exist with the right header" {
    for a in git lazygit github-cli; do
        grep -q '^# group: git$' "$DINGZHI_PATH/apps/$a/install.sh" \
            || { echo "bad: $a"; return 1; }
    done
}

@test "filemanagers group apps exist with the right header" {
    for a in yazi vifm; do
        grep -q '^# group: filemanagers$' "$DINGZHI_PATH/apps/$a/install.sh" \
            || { echo "bad: $a"; return 1; }
    done
}

@test "these app scripts pass shellcheck" {
    for a in kitty tmux neovim vim git lazygit github-cli yazi vifm; do
        run shellcheck -s bash -e SC1091 "$DINGZHI_PATH/apps/$a/install.sh"
        [ "$status" -eq 0 ] || { echo "shellcheck failed: $a"; echo "$output"; return 1; }
    done
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/apps-groups.bats'
```

Expected: 5 fail.

- [ ] **Step 3: Write `apps/kitty/install.sh`**

Ported from `~/tools/apps/kitty/install.sh`; the upstream installer already handles the no-root case.

```bash
#!/usr/bin/env bash
# group: terminal
if command -v kitty >/dev/null 2>&1 || [ -d "$HOME/.local/kitty.app" ]; then
    skip "kitty already installed"
else
    step "installing kitty"
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
fi

if [ -d "$HOME/.local/kitty.app" ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"

    # Make xterm-kitty terminfo available to everything else (vim, ssh targets).
    if [ -d "$HOME/.local/kitty.app/lib/kitty/terminfo" ]; then
        mkdir -p "$HOME/.terminfo"
        cp -R "$HOME/.local/kitty.app/lib/kitty/terminfo/." "$HOME/.terminfo/"
    fi
fi

manage_symlink "$DINGZHI_PATH/configs/kitty" "$HOME/.config/kitty" "kitty config"
```

- [ ] **Step 4: Write `apps/tmux/install.sh`**

Ported from `~/tools/apps/tmux/install.sh`, keeping the 3.4 pin comment.

```bash
#!/usr/bin/env bash
# group: terminal
# tmux 3.5+ has a Landlock sandbox bug that crashes on some Linux kernels;
# the noroot spec pins 3.4 until that is fixed upstream.
pkg_install tmux

manage_symlink "$DINGZHI_PATH/configs/tmux" "$HOME/.config/tmux" "tmux config"

CATPPUCCIN_DIR="$HOME/.config/tmux/plugins/catppuccin/tmux"
if [ -d "$CATPPUCCIN_DIR" ]; then
    skip "catppuccin tmux theme already installed"
else
    step "installing catppuccin tmux theme"
    mkdir -p "$(dirname "$CATPPUCCIN_DIR")"
    git clone -q -b v2.1.3 https://github.com/catppuccin/tmux.git "$CATPPUCCIN_DIR"
fi
```

Note: because `configs/tmux` is symlinked, the plugin clone lands inside the checkout. Add `configs/tmux/plugins/` to `.gitignore`:

```bash
printf 'configs/tmux/plugins/\n' >> .gitignore
```

- [ ] **Step 5: Write `apps/neovim/install.sh`**

Ubuntu's `neovim` is too old for the config, so apt uses the release binary.

```bash
#!/usr/bin/env bash
# group: editors
if pkg_installed neovim; then
    skip "neovim already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    # Ubuntu 24.04 ships 0.9; the shipped config needs 0.10+.
    step "installing neovim from GitHub releases"
    sudo eget neovim/neovim \
        --asset "nvim-linux-x86_64.tar.gz" \
        --file "nvim-linux-x86_64/bin/nvim" \
        --to "$DINGZHI_BIN"
else
    pkg_install neovim
fi

manage_symlink "$DINGZHI_PATH/configs/nvim" "$HOME/.config/nvim" "neovim config"
```

- [ ] **Step 6: Write `apps/vim/install.sh`**

```bash
#!/usr/bin/env bash
# group: editors
pkg_install vim
manage_symlink "$DINGZHI_PATH/configs/vim/vimrc" "$HOME/.vimrc" "vim config"
```

Copy the vimrc across first:

```bash
mkdir -p configs/vim
cp inbox/dotfiles/vim/vimrc configs/vim/vimrc
```

- [ ] **Step 7: Write `apps/git/install.sh`**

```bash
#!/usr/bin/env bash
# group: git
pkg_install git

manage_symlink "$DINGZHI_PATH/configs/git/gitconfig" "$HOME/.gitconfig" "git config"
manage_symlink "$DINGZHI_PATH/configs/git/gitignore_global" \
    "$HOME/.gitignore_global" "global gitignore"
```

- [ ] **Step 8: Write `apps/lazygit/install.sh`**

```bash
#!/usr/bin/env bash
# group: git
if pkg_installed lazygit; then
    skip "lazygit already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    # Not in Ubuntu's repositories.
    step "installing lazygit from GitHub releases"
    sudo eget jesseduffield/lazygit --asset "Linux_x86_64.tar.gz" --to "$DINGZHI_BIN"
else
    pkg_install lazygit
fi

# macOS puts lazygit's config somewhere else entirely.
if [ "$DINGZHI_OS" = "macos" ]; then
    lg_config="$HOME/Library/Application Support/lazygit/config.yml"
else
    lg_config="$HOME/.config/lazygit/config.yml"
fi
manage_symlink "$DINGZHI_PATH/configs/lazygit/config.yml" "$lg_config" "lazygit config"
unset lg_config
```

- [ ] **Step 9: Write `apps/github-cli/install.sh`**

```bash
#!/usr/bin/env bash
# group: git
if pkg_installed github-cli; then
    skip "gh already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    # Needs a third-party apt repository; the release binary avoids that.
    step "installing gh from GitHub releases"
    sudo eget cli/cli --asset "linux_amd64.tar.gz" --file "gh_*/bin/gh" --to "$DINGZHI_BIN"
else
    pkg_install github-cli
fi
```

- [ ] **Step 10: Write `apps/yazi/install.sh`**

```bash
#!/usr/bin/env bash
# group: filemanagers
if pkg_installed yazi; then
    skip "yazi already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    step "installing yazi from GitHub releases"
    sudo eget sxyazi/yazi \
        --asset "x86_64-unknown-linux-musl.zip" \
        --file "yazi-x86_64-unknown-linux-musl/yazi" \
        --to "$DINGZHI_BIN"
else
    pkg_install yazi
fi

manage_symlink "$DINGZHI_PATH/configs/yazi" "$HOME/.config/yazi" "yazi config"
```

- [ ] **Step 11: Write `apps/vifm/install.sh`**

```bash
#!/usr/bin/env bash
# group: filemanagers
pkg_install vifm
manage_symlink "$DINGZHI_PATH/configs/vifm" "$HOME/.config/vifm" "vifm config"
```

- [ ] **Step 12: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/apps-groups.bats'
```

Expected: 5 pass.

- [ ] **Step 13: Verify these groups install on both backends**

```bash
for img in "" "--nosudo"; do
  tests/docker-run.sh $img -- bash -c '
    set -e
    source lib/detect.sh; source lib/ui.sh; source lib/pkg.sh; source lib/link.sh
    source install/check-system.sh; source install/bootstrap.sh
    for a in tmux neovim vim git lazygit github-cli yazi vifm; do
        source "apps/$a/install.sh"
    done
    for c in tmux nvim vim git lazygit gh yazi vifm; do
        command -v "$c" >/dev/null || { echo "MISSING: $c"; exit 1; }
    done
    echo "groups OK"'
done
```

Expected: `groups OK` from both. `kitty` is excluded from this check because its installer wants a graphical target; verify it separately with `tests/docker-run.sh -- bash -c 'source ...; source apps/kitty/install.sh'` and accept a warning if the download succeeds but the app cannot launch.

- [ ] **Step 14: Commit**

```bash
git add apps configs/vim .gitignore tests/unit/apps-groups.bats
git commit -m "feat: terminal, editor, git, and file manager installers"
```

---

### Task 12: App scripts — `shell`, `dev`, `media`, `misc` groups

**Files:**
- Create: `extern/dingzhi/apps/{zsh,bash,uv,cmake,pandoc,poppler,imagemagick,ffmpeg,pngquant,jpegoptim,webp,cheat}/install.sh`
- Test: `extern/dingzhi/tests/unit/apps-rest.bats`

**Interfaces:**
- Consumes: same as Task 10
- Produces: twelve more app scripts. `zsh` and `bash` are the only apps that consult `DINGZHI_SHELLS`.

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/apps-rest.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "shell group apps declare the shell group" {
    for a in zsh bash; do
        grep -q '^# group: shell$' "$DINGZHI_PATH/apps/$a/install.sh" \
            || { echo "bad: $a"; return 1; }
    done
}

@test "dev group apps declare the dev group" {
    for a in uv cmake; do
        grep -q '^# group: dev$' "$DINGZHI_PATH/apps/$a/install.sh" \
            || { echo "bad: $a"; return 1; }
    done
}

@test "media group apps declare the media group" {
    for a in pandoc poppler imagemagick ffmpeg pngquant jpegoptim webp; do
        grep -q '^# group: media$' "$DINGZHI_PATH/apps/$a/install.sh" \
            || { echo "bad: $a"; return 1; }
    done
}

@test "cheat declares the misc group" {
    grep -q '^# group: misc$' "$DINGZHI_PATH/apps/cheat/install.sh"
}

@test "all 34 apps are present" {
    run bash -c "ls -d '$DINGZHI_PATH'/apps/*/ | wc -l"
    [ "$output" -eq 34 ]
}

@test "every app declares exactly one known group" {
    for d in "$DINGZHI_PATH"/apps/*/; do
        g="$(sed -n '2s/^# group: //p' "$d/install.sh")"
        case "$g" in
            core|terminal|editors|git|filemanagers|shell|dev|media|misc) ;;
            *) echo "bad group '$g' in $d"; return 1 ;;
        esac
    done
}

@test "these app scripts pass shellcheck" {
    for a in zsh bash uv cmake pandoc poppler imagemagick ffmpeg pngquant jpegoptim webp cheat; do
        run shellcheck -s bash -e SC1091 "$DINGZHI_PATH/apps/$a/install.sh"
        [ "$status" -eq 0 ] || { echo "shellcheck failed: $a"; echo "$output"; return 1; }
    done
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/apps-rest.bats'
```

Expected: 7 fail.

- [ ] **Step 3: Write the seven trivial media scripts**

`apps/pandoc/install.sh`:

```bash
#!/usr/bin/env bash
# group: media
pkg_install pandoc
```

Repeat verbatim for `poppler`, `imagemagick`, `ffmpeg`, `pngquant`, `jpegoptim`, `webp` — seven files, each with `# group: media` and its own `pkg_install` name.

- [ ] **Step 4: Write `apps/cmake/install.sh`**

```bash
#!/usr/bin/env bash
# group: dev
pkg_install cmake
```

- [ ] **Step 5: Write `apps/uv/install.sh`**

uv is installed during bootstrap because the package table needs it; this script only confirms and reports.

```bash
#!/usr/bin/env bash
# group: dev
if command -v uv >/dev/null 2>&1; then
    skip "uv already installed ($(uv --version))"
else
    step "installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
    export PATH="$HOME/.local/bin:$PATH"
fi
```

- [ ] **Step 6: Write `apps/zsh/install.sh`**

```bash
#!/usr/bin/env bash
# group: shell
case " ${DINGZHI_SHELLS:-zsh} " in
    *" zsh "*) ;;
    *) skip "zsh not selected"; return 0 2>/dev/null || exit 0 ;;
esac

pkg_install zsh

OMZ="$HOME/.oh-my-zsh"
if [ -d "$OMZ" ]; then
    skip "oh-my-zsh already installed"
else
    step "installing oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

P10K="$OMZ/custom/themes/powerlevel10k"
if [ -d "$P10K" ]; then
    skip "powerlevel10k already installed"
else
    step "installing powerlevel10k"
    git clone -q --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K"
fi

inject_line "$HOME/.zshrc" "dingzhi/configs/shell/init.sh" \
    "source \"$DINGZHI_PATH/configs/shell/init.sh\"" "~/.zshrc"
```

- [ ] **Step 7: Write `apps/bash/install.sh`**

```bash
#!/usr/bin/env bash
# group: shell
case " ${DINGZHI_SHELLS:-zsh} " in
    *" bash "*) ;;
    *) skip "bash not selected"; return 0 2>/dev/null || exit 0 ;;
esac

# bash is present on every supported platform; only configuration is needed.
inject_line "$HOME/.bashrc" "dingzhi/configs/shell/init.sh" \
    "source \"$DINGZHI_PATH/configs/shell/init.sh\"" "~/.bashrc"
```

- [ ] **Step 8: Write `apps/cheat/install.sh`**

```bash
#!/usr/bin/env bash
# group: misc
CHEAT_DIR="$HOME/.config/cheat/cheatsheets/community"
if [ -d "$CHEAT_DIR" ]; then
    skip "community cheatsheets already present"
else
    step "cloning community cheatsheets"
    mkdir -p "$(dirname "$CHEAT_DIR")"
    git clone -q --depth=1 https://github.com/cheat/cheatsheets.git "$CHEAT_DIR"
fi

manage_symlink "$DINGZHI_PATH/configs/cheat/conf.yml" \
    "$HOME/.config/cheat/conf.yml" "cheat config"
```

If `~/tools/dotfiles/cheat/` has no `conf.yml`, create a minimal one at `configs/cheat/conf.yml`:

```yaml
---
editor: nvim
colorize: true
style: catppuccin-mocha
formatter: terminal256
cheatpaths:
  - name: community
    path: ~/.config/cheat/cheatsheets/community
    tags: [ community ]
    readonly: true
```

- [ ] **Step 9: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/apps-rest.bats'
```

Expected: 7 pass. If "all 34 apps are present" fails, the count is off — reconcile against the group tables in the spec before continuing.

- [ ] **Step 10: Commit**

```bash
git add apps configs/cheat tests/unit/apps-rest.bats
git commit -m "feat: shell, dev, media, and misc installers"
```

---

### Task 13: `bin/myconvert` and `bin/compressimage`

**Files:**
- Create: `extern/dingzhi/bin/myconvert` (ported from `~/tools/bin/myconvert`)
- Create: `extern/dingzhi/bin/compressimage` (copied from `~/tools/bin/compressimage`)
- Test: `extern/dingzhi/tests/unit/bin.bats`

**Interfaces:**
- Consumes: the `media` group's binaries at runtime
- Produces: two executables on `PATH` via `configs/shell/env.sh`

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/bin.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "both scripts exist and are executable" {
    [ -x "$DINGZHI_PATH/bin/myconvert" ]
    [ -x "$DINGZHI_PATH/bin/compressimage" ]
}

@test "myconvert has no hardcoded personal venv path" {
    run grep -E '/Users/(cche|u1149259)' "$DINGZHI_PATH/bin/myconvert"
    [ "$status" -ne 0 ]
}

@test "myconvert reads the marker venv from the environment" {
    grep -q 'MYCONVERT_MARKER_VENV' "$DINGZHI_PATH/bin/myconvert"
}

@test "myconvert --help exits zero" {
    run "$DINGZHI_PATH/bin/myconvert" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"universal file format converter"* ]]
}

@test "compressimage --help exits zero" {
    run "$DINGZHI_PATH/bin/compressimage" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Batch image compressor"* ]]
}

@test "myconvert fails clearly when marker is requested but unconfigured" {
    printf 'x' > "$HOME/in.pdf"
    run env -u MYCONVERT_MARKER_VENV "$DINGZHI_PATH/bin/myconvert" \
        --force-marker "$HOME/in.pdf" "$HOME/out.md"
    [ "$status" -ne 0 ]
    [[ "$output" == *"MYCONVERT_MARKER_VENV"* ]]
}

@test "myconvert rejects an unsupported conversion" {
    printf 'x' > "$HOME/in.xyz"
    run "$DINGZHI_PATH/bin/myconvert" "$HOME/in.xyz" "$HOME/out.abc"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unsupported conversion"* ]]
}

@test "compressimage passes shellcheck" {
    # myconvert is excluded: it embeds Python heredocs that shellcheck
    # cannot usefully analyse.
    run shellcheck -s bash -e SC1091,SC2016 "$DINGZHI_PATH/bin/compressimage"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/bin.bats'
```

Expected: 8 fail.

- [ ] **Step 3: Copy both scripts**

```bash
cd "$DINGZHI_PATH"
mkdir -p bin
cp inbox/bin/myconvert bin/myconvert
cp inbox/bin/compressimage bin/compressimage
chmod +x bin/myconvert bin/compressimage
```

- [ ] **Step 4: Genericize the marker path in `bin/myconvert`**

Replace this line near the top:

```bash
MARKER_VENV="/Users/cche/softwares/python-envs/pdf/bin/activate"
```

with:

```bash
# Optional: path to a Python venv activate script that has `marker` installed.
# Only needed for --force-marker; every other conversion route works without it.
MARKER_VENV="${MYCONVERT_MARKER_VENV:-}"
```

Then replace the guard inside `convert_marker`:

```bash
  [[ -f "$MARKER_VENV" ]] || die "Marker venv not found at $MARKER_VENV"
```

with:

```bash
  [[ -n "$MARKER_VENV" ]] || die "--force-marker needs MYCONVERT_MARKER_VENV set to the activate script of a venv with 'marker' installed (pip install marker-pdf)"
  [[ -f "$MARKER_VENV" ]] || die "MYCONVERT_MARKER_VENV points at a missing file: $MARKER_VENV"
```

Also fix the dry-run branch in `convert_marker`, which currently expands `$OPENAI_API_KEY` unguarded under `set -u`:

```bash
    display_args="${display_args//$OPENAI_API_KEY/\$OPENAI_API_KEY}"
```

becomes:

```bash
    [[ -n "${OPENAI_API_KEY:-}" ]] && display_args="${display_args//$OPENAI_API_KEY/\$OPENAI_API_KEY}"
```

- [ ] **Step 5: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/bin.bats'
```

Expected: 8 pass.

- [ ] **Step 6: Verify a real conversion end to end**

```bash
tests/docker-run.sh -- bash -c '
  set -e
  source lib/detect.sh; source lib/ui.sh; source lib/pkg.sh; source lib/link.sh
  source install/check-system.sh; source install/bootstrap.sh
  for a in pandoc poppler imagemagick ffmpeg pngquant jpegoptim webp; do
      source "apps/$a/install.sh"
  done
  cd /tmp
  printf "# Title\n\nBody text.\n" > in.md
  ~/dingzhi/bin/myconvert in.md out.html
  grep -q "<h1" out.html && echo "myconvert OK"
  magick -size 400x300 xc:red in.png
  ~/dingzhi/bin/compressimage in.png
  test -f compressed/in.png && echo "compressimage OK"'
```

Expected: `myconvert OK` and `compressimage OK`.

- [ ] **Step 7: Commit**

```bash
git add bin tests/unit/bin.bats
git commit -m "feat: ship myconvert and compressimage"
```

---

### Task 14: `install.sh` — the orchestrator

**Files:**
- Create: `extern/dingzhi/install.sh`
- Test: `extern/dingzhi/tests/unit/install.bats`

**Interfaces:**
- Consumes: every library and install step from Tasks 2–13
- Produces: a single entry point that runs the full flow. Defines `dingzhi_app_group <app>` (reads the `# group:` header) and `dingzhi_apps_in_group <group>` (lists app names), both reused by the TUI in Task 16.

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/install.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "install.sh passes shellcheck" {
    run shellcheck -s bash -e SC1090,SC1091 "$DINGZHI_PATH/install.sh"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}

@test "dingzhi_app_group reads the header" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/install.sh" --lib-only
    run dingzhi_app_group bat
    [ "$output" = "core" ]
}

@test "dingzhi_apps_in_group lists the media group" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/install.sh" --lib-only
    run dingzhi_apps_in_group media
    [[ "$output" == *pandoc* ]]
    [[ "$output" == *ffmpeg* ]]
    [[ "$output" != *bat* ]]
}

@test "--lib-only does not install anything" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/install.sh" --lib-only
    run command -v lazygit
    [ "$status" -ne 0 ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/install.bats'
```

Expected: 4 fail.

- [ ] **Step 3: Write the implementation**

`extern/dingzhi/install.sh`:

```bash
#!/usr/bin/env bash
# dingzhi installer.
#
#   bash install.sh                 full install
#   source install.sh --lib-only    load libraries and helpers, install nothing
#
# Environment:
#   DINGZHI_NONINTERACTIVE=1  accept all defaults
#   DINGZHI_BACKEND=...       force brew | apt | noroot

set -e

DINGZHI_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DINGZHI_PATH

# shellcheck source=lib/detect.sh
. "$DINGZHI_PATH/lib/detect.sh"
# shellcheck source=lib/ui.sh
. "$DINGZHI_PATH/lib/ui.sh"
# shellcheck source=lib/pkg.sh
. "$DINGZHI_PATH/lib/pkg.sh"
# shellcheck source=lib/link.sh
. "$DINGZHI_PATH/lib/link.sh"

# dingzhi_app_group <app> -> the group declared on line 2 of its install.sh
dingzhi_app_group() {
    sed -n '2s/^# group: //p' "$DINGZHI_PATH/apps/$1/install.sh"
}

# dingzhi_apps_in_group <group> -> app names, one per line
dingzhi_apps_in_group() {
    local want="$1" d name
    for d in "$DINGZHI_PATH"/apps/*/; do
        name="$(basename "$d")"
        [ "$(dingzhi_app_group "$name")" = "$want" ] && printf '%s\n' "$name"
    done
    return 0
}

# dingzhi_all_apps -> every app name, one per line
dingzhi_all_apps() {
    local d
    for d in "$DINGZHI_PATH"/apps/*/; do
        basename "$d"
    done
}

# Sourced with --lib-only: stop here, having defined everything.
case "${1:-}" in
    --lib-only) return 0 2>/dev/null || exit 0 ;;
esac

trap 'echo "!! dingzhi installation failed. Retry with: bash $DINGZHI_PATH/install.sh" >&2' ERR

say "dingzhi $(cat "$DINGZHI_PATH/version")"

. "$DINGZHI_PATH/install/check-system.sh"
. "$DINGZHI_PATH/install/bootstrap.sh"
. "$DINGZHI_PATH/install/choices.sh"
. "$DINGZHI_PATH/install/identification.sh"

say "Installing applications"

DINGZHI_FAILED=""
for group in $DINGZHI_GROUPS; do
    for app in $(dingzhi_apps_in_group "$group"); do
        step "$app"
        # A failing app is reported and skipped, not fatal: one broken
        # installer must not cost the user the other 33.
        if ! ( . "$DINGZHI_PATH/apps/$app/install.sh" ); then
            warn "$app failed"
            DINGZHI_FAILED="$DINGZHI_FAILED $app"
        fi
    done
done

link_summary

if [ -n "$DINGZHI_FAILED" ]; then
    warn "These apps failed:$DINGZHI_FAILED"
    warn "Re-run 'dingzhi install' to retry them individually."
else
    say "All selected apps installed."
fi

say "Done. Open a new terminal, or run: exec \$SHELL -l"
```

Note the app loop runs each script in a subshell `( . ... )` so a `set -e` abort inside one app cannot kill the run — but that also means an app cannot export variables to later apps. No app needs to.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/install.bats'
```

Expected: 4 pass.

- [ ] **Step 5: Run the full installer in both containers**

```bash
tests/docker-run.sh -- bash -c 'DINGZHI_NONINTERACTIVE=1 bash install.sh'
tests/docker-run.sh --nosudo -- bash -c 'DINGZHI_NONINTERACTIVE=1 bash install.sh'
```

Expected: exit 0 in both, with a final "All selected apps installed." If any app is listed as failed, fix that app's script before continuing.

- [ ] **Step 6: Commit**

```bash
git add install.sh tests/unit/install.bats
git commit -m "feat: installer orchestrator"
```

---

### Task 15: `boot.sh` — the one-line entry point

**Files:**
- Create: `extern/dingzhi/boot.sh`
- Test: `extern/dingzhi/tests/unit/boot.bats`

**Interfaces:**
- Consumes: nothing (runs before the repository exists on the target machine)
- Produces: a clone at `${DINGZHI_INSTALL_DIR:-$HOME/.local/share/dingzhi}`, then sources its `install.sh`

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/boot.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "boot.sh passes shellcheck" {
    run shellcheck -s bash -e SC1090,SC1091 "$DINGZHI_PATH/boot.sh"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}

@test "boot.sh honors DINGZHI_INSTALL_DIR" {
    grep -q 'DINGZHI_INSTALL_DIR' "$DINGZHI_PATH/boot.sh"
}

@test "boot.sh refuses to clobber an existing checkout without consent" {
    grep -q 'already exists' "$DINGZHI_PATH/boot.sh"
}

@test "boot.sh clones and installs into a scratch directory" {
    # Clone from the working tree rather than the network.
    DINGZHI_REPO="file://$DINGZHI_PATH" \
    DINGZHI_INSTALL_DIR="$HOME/scratch-dingzhi" \
    DINGZHI_NONINTERACTIVE=1 \
    DINGZHI_SKIP_INSTALL=1 \
        run bash "$DINGZHI_PATH/boot.sh"
    [ -f "$HOME/scratch-dingzhi/version" ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/boot.bats'
```

Expected: 4 fail.

- [ ] **Step 3: Write the implementation**

`extern/dingzhi/boot.sh`:

```bash
#!/usr/bin/env bash
# dingzhi bootstrap.
#
#   curl -fsSL https://raw.githubusercontent.com/chongchonghe/dingzhi/main/boot.sh | bash
#
# Environment:
#   DINGZHI_INSTALL_DIR  where to clone      (default ~/.local/share/dingzhi)
#   DINGZHI_REPO         where to clone from (default the GitHub remote)
#   DINGZHI_REF          branch or tag       (default main)
#   DINGZHI_SKIP_INSTALL clone only, for tests

set -e

DINGZHI_INSTALL_DIR="${DINGZHI_INSTALL_DIR:-$HOME/.local/share/dingzhi}"
DINGZHI_REPO="${DINGZHI_REPO:-https://github.com/chongchonghe/dingzhi.git}"
DINGZHI_REF="${DINGZHI_REF:-main}"

cat <<'ASCII'
   _ _              _    _
  | (_)_ _  __ _ ___| |_ (_)
  | | | ' \/ _` |_ / ' \| |
  |_|_|_||_\__, /___|_||_|_|
           |___/
ASCII

echo "=> dingzhi: a terminal environment for macOS and Linux"
echo

command -v git >/dev/null 2>&1 || {
    echo "!! git is required. Install it and re-run." >&2
    exit 1
}

if [ -d "$DINGZHI_INSTALL_DIR/.git" ]; then
    echo "=> $DINGZHI_INSTALL_DIR already exists; updating instead of cloning"
    git -C "$DINGZHI_INSTALL_DIR" fetch --quiet origin "$DINGZHI_REF"
    git -C "$DINGZHI_INSTALL_DIR" checkout --quiet "$DINGZHI_REF"
    git -C "$DINGZHI_INSTALL_DIR" pull --quiet --ff-only
elif [ -e "$DINGZHI_INSTALL_DIR" ]; then
    echo "!! $DINGZHI_INSTALL_DIR already exists and is not a dingzhi checkout." >&2
    echo "!! Move it aside or set DINGZHI_INSTALL_DIR to somewhere else." >&2
    exit 1
else
    echo "=> cloning dingzhi into $DINGZHI_INSTALL_DIR"
    mkdir -p "$(dirname "$DINGZHI_INSTALL_DIR")"
    git clone --quiet --branch "$DINGZHI_REF" "$DINGZHI_REPO" "$DINGZHI_INSTALL_DIR"
fi

[ "${DINGZHI_SKIP_INSTALL:-0}" = "1" ] && exit 0

echo "=> starting installation"
# shellcheck source=install.sh
. "$DINGZHI_INSTALL_DIR/install.sh"
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/boot.bats'
```

Expected: 4 pass.

- [ ] **Step 5: Verify a true end-to-end boot from a local clone source**

```bash
tests/docker-run.sh -- bash -c '
  set -e
  export DINGZHI_REPO="file:///home/dev/dingzhi"
  export DINGZHI_INSTALL_DIR="$HOME/.local/share/dingzhi"
  export DINGZHI_NONINTERACTIVE=1
  bash /home/dev/dingzhi/boot.sh
  test -x "$HOME/.local/share/dingzhi/install.sh" || test -f "$HOME/.local/share/dingzhi/install.sh"
  echo "boot OK"'
```

Expected: `boot OK`. This is the closest possible rehearsal of the real one-liner without a published remote.

- [ ] **Step 6: Commit**

```bash
git add boot.sh tests/unit/boot.bats
git commit -m "feat: one-line bootstrap entry point"
```

---

### Task 16: `bin/dingzhi` — the TUI

**Files:**
- Create: `extern/dingzhi/bin/dingzhi`
- Test: `extern/dingzhi/tests/unit/tui.bats`

**Interfaces:**
- Consumes: `dingzhi_app_group`, `dingzhi_apps_in_group`, `dingzhi_all_apps` from `install.sh --lib-only`; `pkg_installed`, `pkg_remove`; `choose_multi`, `confirm`
- Produces: `dingzhi` with subcommands `install`, `remove`, `update`, `doctor`, and no-argument menu mode. `doctor` exits 0 when everything is healthy and 1 otherwise, so it can gate the integration test.

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/tui.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "dingzhi is executable" {
    [ -x "$DINGZHI_PATH/bin/dingzhi" ]
}

@test "dingzhi passes shellcheck" {
    run shellcheck -s bash -e SC1090,SC1091 "$DINGZHI_PATH/bin/dingzhi"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}

@test "dingzhi --help lists every subcommand" {
    run "$DINGZHI_PATH/bin/dingzhi" --help
    [ "$status" -eq 0 ]
    for c in install remove update doctor; do
        [[ "$output" == *"$c"* ]] || { echo "missing subcommand: $c"; return 1; }
    done
}

@test "dingzhi doctor runs and reports every app" {
    run "$DINGZHI_PATH/bin/dingzhi" doctor
    [[ "$output" == *"bat"* ]]
    [[ "$output" == *"neovim"* ]]
    [[ "$output" == *"backend"* ]]
}

@test "dingzhi doctor exits non-zero when apps are missing" {
    run "$DINGZHI_PATH/bin/dingzhi" doctor
    [ "$status" -ne 0 ]
}

@test "dingzhi rejects an unknown subcommand" {
    run "$DINGZHI_PATH/bin/dingzhi" nonsense
    [ "$status" -ne 0 ]
    [[ "$output" == *"unknown"* ]]
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/tui.bats'
```

Expected: 6 fail.

- [ ] **Step 3: Write the implementation**

`extern/dingzhi/bin/dingzhi`:

```bash
#!/usr/bin/env bash
# dingzhi control command.
#
#   dingzhi            interactive menu
#   dingzhi install    install apps that are not yet present
#   dingzhi remove     remove apps that provide an uninstall script
#   dingzhi update     git pull and re-run the installer
#   dingzhi doctor     report what is installed, linked, and configured

set -e

# Locate the checkout from this script, following the symlink if bin/ is on PATH.
_self="${BASH_SOURCE[0]}"
while [ -L "$_self" ]; do
    _self="$(cd "$(dirname "$_self")" && pwd)/$(readlink "$_self")"
done
DINGZHI_PATH="$(cd "$(dirname "$_self")/.." && pwd)"
export DINGZHI_PATH
unset _self

# shellcheck source=../install.sh
. "$DINGZHI_PATH/install.sh" --lib-only

usage() {
    cat <<'EOF'
dingzhi — manage your dingzhi installation

Usage:
  dingzhi              open the interactive menu
  dingzhi install      install apps that are not yet present
  dingzhi remove       remove apps that provide an uninstall script
  dingzhi update       git pull and re-run the installer
  dingzhi doctor       report installed apps, linked configs, and shell setup
  dingzhi --help       show this message
EOF
}

cmd_install() {
    local candidates="" app
    for app in $(dingzhi_all_apps); do
        pkg_installed "$app" || candidates="$candidates $app"
    done

    if [ -z "$candidates" ]; then
        say "Everything is already installed."
        return 0
    fi

    local chosen
    # shellcheck disable=SC2086
    chosen="$(choose_multi "Install which apps?" "" $candidates)"
    [ -n "$chosen" ] || { say "Nothing selected."; return 0; }

    for app in $chosen; do
        step "$app"
        ( . "$DINGZHI_PATH/apps/$app/install.sh" ) || warn "$app failed"
    done
}

cmd_remove() {
    # Only offer apps we can actually undo. An app without an uninstall.sh is
    # install-only, and the menu says so by omission.
    local removable="" app
    for app in $(dingzhi_all_apps); do
        [ -f "$DINGZHI_PATH/apps/$app/uninstall.sh" ] \
            && pkg_installed "$app" \
            && removable="$removable $app"
    done

    if [ -z "$removable" ]; then
        say "No installed app provides an uninstall script."
        return 0
    fi

    local chosen
    # shellcheck disable=SC2086
    chosen="$(choose_multi "Remove which apps?" "" $removable)"
    [ -n "$chosen" ] || { say "Nothing selected."; return 0; }

    # shellcheck disable=SC2086
    confirm "Really remove:$(printf ' %s' $chosen)?" || { say "Cancelled."; return 0; }

    for app in $chosen; do
        step "$app"
        ( . "$DINGZHI_PATH/apps/$app/uninstall.sh" ) || warn "$app removal failed"
    done
}

cmd_update() {
    say "Updating dingzhi"
    git -C "$DINGZHI_PATH" pull --ff-only
    say "Re-running the installer"
    bash "$DINGZHI_PATH/install.sh"
}

cmd_doctor() {
    local app problems=0 mark

    say "dingzhi $(cat "$DINGZHI_PATH/version")"
    step "path:    $DINGZHI_PATH"
    step "os:      $DINGZHI_OS/$DINGZHI_ARCH"
    step "backend: $DINGZHI_BACKEND"
    step "bindir:  $DINGZHI_BIN"
    echo

    say "Applications"
    for app in $(dingzhi_all_apps); do
        if pkg_installed "$app"; then
            mark="ok     "
        else
            mark="MISSING"
            problems=$((problems + 1))
        fi
        printf '    %s  %-14s (%s)\n' "$mark" "$app" "$(dingzhi_app_group "$app")"
    done
    echo

    say "Shell integration"
    local rc found=0
    for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [ -f "$rc" ] && grep -q 'dingzhi/configs/shell/init.sh' "$rc"; then
            printf '    ok       %s\n' "$rc"
            found=1
        fi
    done
    if [ "$found" -eq 0 ]; then
        printf '    MISSING  no shell rc sources dingzhi\n'
        problems=$((problems + 1))
    fi
    echo

    say "Git identity"
    if [ -f "$HOME/.gitconfig.local" ]; then
        printf '    ok       ~/.gitconfig.local\n'
    else
        printf '    MISSING  ~/.gitconfig.local\n'
        problems=$((problems + 1))
    fi

    echo
    if [ "$problems" -eq 0 ]; then
        say "No problems found."
        return 0
    fi
    warn "$problems problem(s) found."
    return 1
}

cmd_menu() {
    local choice
    choice="$(gum choose \
        --header "dingzhi" \
        "Install apps" "Remove apps" "Update dingzhi" "Doctor" "Quit" 2>/dev/null)" \
        || { usage; return 0; }

    case "$choice" in
        "Install apps")   cmd_install ;;
        "Remove apps")    cmd_remove ;;
        "Update dingzhi") cmd_update ;;
        "Doctor")         cmd_doctor ;;
        *)                : ;;
    esac
}

case "${1:-}" in
    install) cmd_install ;;
    remove)  cmd_remove ;;
    update)  cmd_update ;;
    doctor)  cmd_doctor ;;
    -h|--help) usage ;;
    "")      cmd_menu ;;
    *)       warn "unknown subcommand: $1"; usage; exit 1 ;;
esac
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/tui.bats'
```

Expected: 6 pass.

- [ ] **Step 5: Verify doctor reports clean after a full install**

```bash
tests/docker-run.sh -- bash -c '
  DINGZHI_NONINTERACTIVE=1 bash install.sh >/dev/null 2>&1
  bin/dingzhi doctor'
```

Expected: exit 0 and "No problems found." Any `MISSING` line names an app whose installer silently failed — fix it before continuing.

- [ ] **Step 6: Commit**

```bash
git add bin/dingzhi tests/unit/tui.bats
git commit -m "feat: dingzhi control command"
```

---

### Task 17: Uninstall scripts

Written only for apps where removal is a genuine one-liner. Everything else stays install-only, and `dingzhi remove` omits it.

**Files:**
- Create: `extern/dingzhi/apps/{bat,eza,fd,fzf,ripgrep,zoxide,jq,tlrc,highlight,vifm,cmake,pandoc,ffmpeg,pngquant,jpegoptim}/uninstall.sh`
- Test: `extern/dingzhi/tests/unit/uninstall.bats`

**Interfaces:**
- Consumes: `pkg_remove`, `unlink_managed`
- Produces: 15 `uninstall.sh` files. An app with a config symlink must unlink it as well as remove the package.

- [ ] **Step 1: Write the failing test**

`extern/dingzhi/tests/unit/uninstall.bats`:

```bash
#!/usr/bin/env bats

load ../helpers

UNINSTALLABLE="bat eza fd fzf ripgrep zoxide jq tlrc highlight vifm cmake pandoc ffmpeg pngquant jpegoptim"

setup() {
    setup_dingzhi_env
}

@test "the expected apps have uninstall scripts" {
    for a in $UNINSTALLABLE; do
        [ -f "$DINGZHI_PATH/apps/$a/uninstall.sh" ] || { echo "missing: $a"; return 1; }
    done
}

@test "uninstall scripts pass shellcheck" {
    for a in $UNINSTALLABLE; do
        run shellcheck -s bash -e SC1091 "$DINGZHI_PATH/apps/$a/uninstall.sh"
        [ "$status" -eq 0 ] || { echo "shellcheck failed: $a"; echo "$output"; return 1; }
    done
}

@test "apps with config symlinks unlink them on removal" {
    grep -q 'unlink_managed' "$DINGZHI_PATH/apps/bat/uninstall.sh"
    grep -q 'unlink_managed' "$DINGZHI_PATH/apps/vifm/uninstall.sh"
}

@test "no uninstall script exists for an app that cannot be cleanly removed" {
    # kitty, zsh, and cheat all leave state we will not delete on the user's behalf.
    for a in kitty zsh bash cheat git; do
        [ ! -f "$DINGZHI_PATH/apps/$a/uninstall.sh" ] \
            || { echo "unexpected uninstall.sh: $a"; return 1; }
    done
}

@test "install then uninstall then install leaves the app working" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/ui.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    source "$DINGZHI_PATH/lib/link.sh"
    sudo apt-get update -qq
    ( . "$DINGZHI_PATH/apps/jq/install.sh" )
    command -v jq
    ( . "$DINGZHI_PATH/apps/jq/uninstall.sh" )
    run command -v jq
    [ "$status" -ne 0 ]
    ( . "$DINGZHI_PATH/apps/jq/install.sh" )
    command -v jq
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/uninstall.bats'
```

Expected: 5 fail.

- [ ] **Step 3: Write the thirteen simple uninstall scripts**

`apps/eza/uninstall.sh`:

```bash
#!/usr/bin/env bash
pkg_remove eza
```

Repeat verbatim for `fd`, `fzf`, `ripgrep`, `zoxide`, `jq`, `tlrc`, `highlight`, `cmake`, `pandoc`, `ffmpeg`, `pngquant`, `jpegoptim`, substituting the name. Thirteen files.

- [ ] **Step 4: Write the two with config symlinks**

`apps/bat/uninstall.sh`:

```bash
#!/usr/bin/env bash
pkg_remove bat
unlink_managed "$HOME/.config/bat" "bat config"
rm -f "$HOME/.local/bin/bat"
```

`apps/vifm/uninstall.sh`:

```bash
#!/usr/bin/env bash
pkg_remove vifm
unlink_managed "$HOME/.config/vifm" "vifm config"
```

- [ ] **Step 5: Run the tests to verify they pass**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit/uninstall.bats'
```

Expected: 5 pass.

- [ ] **Step 6: Commit**

```bash
git add apps tests/unit/uninstall.bats
git commit -m "feat: uninstall scripts for cleanly removable apps"
```

---

### Task 18: Integration test, README, and release

**Files:**
- Create: `extern/dingzhi/tests/integration/install-twice.sh`
- Modify: `extern/dingzhi/README.md`
- Test: the integration script is itself the test

**Interfaces:**
- Consumes: everything
- Produces: a single command that proves the whole system works and is idempotent on both backends

- [ ] **Step 1: Write the failing integration test**

`extern/dingzhi/tests/integration/install-twice.sh`:

```bash
#!/usr/bin/env bash
# Run the full dingzhi installer twice and assert the second run changes
# nothing. Intended to run INSIDE a test container.
#
#   tests/docker-run.sh -- bash tests/integration/install-twice.sh
set -euo pipefail

DINGZHI_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DINGZHI_NONINTERACTIVE=1
export DINGZHI_GIT_NAME="Test User"
export DINGZHI_GIT_EMAIL="test@example.com"

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "### first install"
bash "$DINGZHI_PATH/install.sh" 2>&1 | tee /tmp/run1.log
grep -q "All selected apps installed." /tmp/run1.log \
    || fail "first run reported app failures"

echo "### doctor after first install"
"$DINGZHI_PATH/bin/dingzhi" doctor | tee /tmp/doctor1.log
grep -q "No problems found." /tmp/doctor1.log \
    || fail "doctor reported problems after a clean install"

echo "### second install (must be idempotent)"
bash "$DINGZHI_PATH/install.sh" 2>&1 | tee /tmp/run2.log

# Idempotency: no backup files created, and the shell rc line appears once.
if ls "$HOME"/*.backup.* >/dev/null 2>&1; then
    fail "second run backed up a file it had already linked"
fi

for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [ -f "$rc" ] || continue
    n="$(grep -c 'dingzhi/configs/shell/init.sh' "$rc" || true)"
    [ "$n" -le 1 ] || fail "$rc has $n dingzhi source lines; expected at most 1"
done

echo "### doctor after second install"
"$DINGZHI_PATH/bin/dingzhi" doctor >/dev/null || fail "doctor failed after re-run"

echo "### PASS: install is idempotent on backend $(
    bash -c "source '$DINGZHI_PATH/lib/detect.sh' && echo \$DINGZHI_BACKEND")"
```

Make it executable: `chmod +x tests/integration/install-twice.sh`.

- [ ] **Step 2: Run it and expect failures to surface**

```bash
tests/docker-run.sh -- bash tests/integration/install-twice.sh
```

Expected: this is the first time everything runs together. Fix whatever it reports — most likely candidates are apps whose `pkg_installed` check does not match the binary they actually install, and configs that get re-linked because `manage_symlink` resolves the source path differently the second time.

- [ ] **Step 3: Run it on the no-root backend**

```bash
tests/docker-run.sh --nosudo bash tests/integration/install-twice.sh
```

Expected: `PASS: install is idempotent on backend noroot`.

- [ ] **Step 4: Run the whole unit suite one final time on both images**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit'
tests/docker-run.sh --nosudo -- bash -c 'bats tests/unit'
```

Expected: every test passes in both.

- [ ] **Step 5: Remove `inbox/`**

Its whole contents have been ported by now: `configs/` (Task 9), `configs/vim`
(Task 11), `bin/` (Task 13), `themes/catppuccin` (Task 9). Keeping it would ship
3 MB of duplicate, un-genericized configs — including the personal absolute
paths Task 9 exists to strip.

```bash
cd "$DINGZHI_PATH"
git rm -r --quiet inbox
```

Verify nothing still references it:

```bash
grep -rn "inbox/" --exclude-dir=.git --exclude=plan.md . && echo "STILL REFERENCED" || echo "clean"
```

Expected: `clean`.

- [ ] **Step 6: Write the real README**

Replace `extern/dingzhi/README.md`:

````markdown
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

Plus two utilities: `myconvert` (convert between document, image, video, audio,
and data formats) and `compressimage` (batch-compress publication figures).

## Supported platforms

| Platform | How packages are installed |
|---|---|
| macOS | Homebrew |
| Ubuntu / Debian with sudo | apt, falling back to GitHub releases where needed |
| Any other Linux, including HPC login nodes | eget + pixi, entirely without root |

dingzhi never requires root on the third path. Binaries go to `~/local/bin`.

## After installing

```bash
dingzhi            # interactive menu
dingzhi install    # install apps you skipped
dingzhi remove     # remove apps that can be cleanly removed
dingzhi update     # git pull and re-run the installer
dingzhi doctor     # report what is installed, linked, and configured
```

Re-running the installer is always safe: it changes nothing that is already
correct.

## Configuration

Configs live in `configs/` and are **symlinked** into `~/.config`, so
`dingzhi update` updates them in place. Any real file dingzhi would displace is
backed up to `<file>.backup.<timestamp>` first.

Your git identity goes to `~/.gitconfig.local`, which the shipped gitconfig
includes. dingzhi never commits your name or email.

dingzhi is deliberately opinionated: the theme is Catppuccin Mocha, dark only,
with no switcher. To change what it installs or how it looks, fork it.

## Development

```bash
tests/docker-build.sh both                                  # build test images
tests/docker-run.sh -- bash -c 'bats tests/unit'            # unit tests, apt backend
tests/docker-run.sh --nosudo -- bash -c 'bats tests/unit'   # unit tests, no-root backend
tests/docker-run.sh -- bash tests/integration/install-twice.sh
```

Never run the installer on your own machine while developing — it writes to the
same paths your real configuration uses. The containers exist for that reason.

## License

MIT
````

- [ ] **Step 7: Tag the release**

```bash
git add tests/integration README.md
git commit -m "test: end-to-end idempotency check and README"
git tag -a v0.1.0 -m "dingzhi 0.1.0"
```

- [ ] **Step 8: Final verification**

```bash
tests/docker-run.sh -- bash -c 'bats tests/unit' \
  && tests/docker-run.sh --nosudo -- bash -c 'bats tests/unit' \
  && tests/docker-run.sh -- bash tests/integration/install-twice.sh \
  && tests/docker-run.sh --nosudo bash tests/integration/install-twice.sh \
  && echo "ALL GREEN"
```

Expected: `ALL GREEN`. Do not report the project complete without seeing that string.

---

## Deferred to a later version

Recorded so they are not silently dropped:

- **macOS verification.** Every brew path is written but never executed during development, per Global Constraint 2. Before publishing, run the installer on a clean macOS VM or a spare Mac.
- **Homebrew casks / GUI apps.** Out of scope by design.
- **Doom Emacs.** Excluded from v1.
- **arm64 Linux.** The `noroot` eget asset filters are x86_64-only; `check-system.sh` warns rather than aborting.
- **`apps/shell/` bug in `~/tools`.** `macos_install.sh` and `hpc_install.sh` both call `run_config shell` for a directory that does not exist. Not dingzhi's problem, but worth fixing upstream.
