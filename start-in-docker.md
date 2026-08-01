# Implementing dingzhi inside the container

You are Claude Code running **inside a dingzhi test container**. This file tells
you where you are, what the rules are, and how to proceed.

## Where you are

- The dingzhi working tree is mounted at `~/dingzhi` — this is a **live mount of
  the host repository**. Every edit you make here appears on the host
  immediately. It is not a copy. It is also the *only* mount: `docs/` is
  inside it, so nothing this container needs lives elsewhere.
- The container is disposable. `docker run --rm` means anything written outside
  `~/dingzhi` disappears when the shell exits. That is deliberate: it is what
  makes running the installer safe.
- Your image is one of three. Check which one before assuming anything:

  ```bash
  source ~/dingzhi/lib/detect.sh 2>/dev/null && echo "backend: $DINGZHI_BACKEND"
  sudo -n true 2>/dev/null && echo "sudo: yes" || echo "sudo: no"
  ```

  | Image | Backend | sudo | Toolkit |
  |---|---|---|---|
  | `dingzhi-sudo` | `apt` | yes | yes |
  | `dingzhi-nosudo` | `noroot` (eget + pixi) | no | yes |
  | `dingzhi-clean` | `apt` | yes | no |

## The documents that govern this work

They live in the repository, at `~/dingzhi/docs/`:

- Spec: `~/dingzhi/docs/design.md`
- Plan: `~/dingzhi/docs/plan.md`

They are inside the repo on purpose. The working tree is the one thing every
way of starting this container mounts, so the governing documents travel with
it — no separate mount to forget, and no launch method that silently drops them.

Read the plan first. **Do not invent requirements from this file alone** — it is
orientation, not the spec. If `~/dingzhi/docs/plan.md` is missing, stop and say
so rather than guessing at the design.

## Rules

1. **Follow the plan task by task, in order.** Each task is TDD: write the
   failing test, run it, watch it fail, implement, watch it pass, commit. Do not
   skip the "watch it fail" step — a test that never failed has not been shown
   to test anything.
2. **Bash 3.2 compatible.** macOS ships bash 3.2, so: no `declare -A`, no
   `mapfile`/`readarray`, no `${var^^}`/`${var,,}`, no `[[ -v var ]]`, no
   globstar. Use `case` statements where you would reach for an associative
   array. The container runs bash 5, so it will *not* catch these for you —
   `tests/unit/apps-core.bats` has a grep-based guard, but it is not exhaustive.
   Think before you use a modern builtin.
3. **No absolute paths to any particular home or checkout.** `DINGZHI_PATH` is
   always derived from `BASH_SOURCE`. Never write `/Users/...`, `/home/dev/...`,
   or `$HOME/tools`.
4. **Every install script must be idempotent.** Running it twice must succeed,
   change nothing the second time, and print a `[skip]` line saying so.
5. **Tests never touch the real `$HOME`.** Every `.bats` file calls
   `setup_dingzhi_env` in `setup()`, which redirects `HOME` into
   `$BATS_TEST_TMPDIR`. If you write a test without it, you are editing the
   container's real home — and if someone ever runs the suite outside a
   container, their actual dotfiles.
6. **Catppuccin Mocha, dark only.** No light variant, no theme switcher, no
   `~/.darktheme`. This is a deliberate product decision, not an omission.
7. **Conventional Commits**, one commit per completed task.

## Running things

All commands run from `~/dingzhi`.

```bash
# The whole unit suite
bats tests/unit

# One file, verbose
bats tests/unit/detect.bats -t

# Lint a script the way the tests do
shellcheck -s bash -e SC1091 apps/bat/install.sh

# The full installer, non-interactive
DINGZHI_NONINTERACTIVE=1 bash install.sh

# The idempotency check (once Task 18 exists)
bash tests/integration/install-twice.sh

# Health report
bin/dingzhi doctor
```

Running the installer **inside the container is expected and safe** — that is
what the container is for. Running it on the host is forbidden: it writes to
`~/.config`, `~/.zshrc`, and `~/.gitconfig`, the same paths the host's real
configuration uses.

### Forcing a backend without rebuilding

`lib/detect.sh` honours a pre-set `DINGZHI_BACKEND`, so you can exercise the
resolver for a platform you are not on:

```bash
DINGZHI_BACKEND=brew bash -c 'source lib/detect.sh; source lib/ui.sh;
                             source lib/pkg.sh; pkg_resolve fd brew'
```

This only tests *resolution*. It cannot test that Homebrew actually installs
anything — there is no Homebrew here. macOS is verified by reading, and later on
a real Mac.

## Committing

The mount is the host's real git repository, so your commits are real commits on
the host. Git identity is not configured in the container; set it per-command
rather than writing a global config into a disposable image:

```bash
git -c user.name="ChongChong He" -c user.email="chongchonghe99@gmail.com" \
    commit -m "feat: platform and backend detection"
```

Or, once, per container session:

```bash
git config --global user.name "ChongChong He"
git config --global user.email "chongchonghe99@gmail.com"
```

## Two traps specific to this project

**`gh` is preinstalled in `dingzhi-sudo` and `dingzhi-nosudo`.** It is also a
dingzhi app (`github-cli`). So `pkg_installed github-cli` returns true and Task
11's gh installer will appear to work without ever running. To test it honestly:

```bash
# from the HOST
tests/docker-run.sh --clean -- bash -c '...'
```

`dingzhi-clean` has no `gh`. Nothing else in the toolkit overlaps with dingzhi's
34 apps — `tests/unit/smoke.bats` asserts that, so if you add a package to the
Dockerfile that dingzhi also manages, the suite will tell you.

**Symlinked configs land inside the checkout.** `configs/tmux` is symlinked to
`~/.config/tmux`, so the catppuccin plugin clone in Task 11 writes into the
repository. `.gitignore` already excludes `configs/tmux/plugins/`. If you add
another app whose config directory receives runtime state, ignore that path too
or the working tree will never be clean again.

## Where to start

```bash
cd ~/dingzhi
git log --oneline          # what is already done
bats tests/unit            # current state — should be green
less ~/dingzhi/docs/plan.md
```

Then start at the first task with unchecked steps. If everything through Task 1
is committed, that is **Task 2: `lib/detect.sh`**.
