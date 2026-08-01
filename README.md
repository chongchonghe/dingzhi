# dingzhi

Turn a fresh macOS or Linux machine into a fully configured terminal
development environment with one command.

Status: under development.

- Design: [`docs/design.md`](docs/design.md)
- Implementation plan: [`docs/plan.md`](docs/plan.md)
- Working inside the test container: [`start-in-docker.md`](start-in-docker.md)

## Development

```bash
tests/docker-build.sh both                                 # build test images
tests/docker-run.sh -- bash -c 'bats tests/unit'           # apt backend
tests/docker-run.sh --nosudo -- bash -c 'bats tests/unit'  # no-root backend
tests/docker-run.sh                                        # interactive shell
```

The `dingzhi-sudo` image exercises the apt backend; `dingzhi-nosudo` runs as a
user who cannot escalate, exercising the eget+pixi no-root path. Both include
the Claude Code CLI. The working tree is mounted at `~/dingzhi` at run time, so
editing a script never requires a rebuild.

Never run the installer on your own machine while developing — it writes to
`~/.config`, `~/.zshrc`, and `~/.gitconfig`, the same paths your real
configuration uses. The containers exist for that reason.
