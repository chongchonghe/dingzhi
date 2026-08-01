# vifm-zoxide

Frecency-based directory jumping for [vifm](https://vifm.info) via [zoxide](https://github.com/ajeetdsouza/zoxide).

## Features

- `:z <keywords>` — jump to the best frecent match
- `:za` — manually register the current directory
- Auto-tracking of every visited directory via a `DirEnter` autocmd in `vifmrc`

## Installation

Requires zoxide to be installed and on `$PATH`.

The plugin (`plugins/zoxide/`) is loaded automatically by vifm 0.13+. The
following lines must also be present in `vifmrc`:

```
" Keymap
nnoremap ,z :z<space>

" Auto-tracking
autocmd DirEnter * !zoxide add %d > /dev/null 2>&1 &
```

## Usage

| Command / key  | Action                                      |
|----------------|---------------------------------------------|
| `,z <query>`   | Jump to best frecent match for query        |
| `:z foo bar`   | Same — multiple keywords narrow the match   |
| `:za`          | Add current directory to zoxide database    |

## Performance

**Navigation lag: none.** The `DirEnter` autocmd appends `&` to run `zoxide add`
in the background, so vifm never waits for it.

**Database size: bounded.** zoxide uses a frequency algorithm — repeated visits
to the same path raise its score rather than creating duplicate entries. The
database self-prunes low-scoring entries once it exceeds a configurable age
limit (`ZOXIDE_MAXAGE`, default 10000). No manual maintenance needed.

**Burst traffic.** Rapid navigation (e.g. holding `j`/`k` in miller view) can
fire many `DirEnter` events in quick succession, spawning a burst of short-lived
background processes. This is harmless in practice, but if it ever becomes a
concern the autocmd can be rate-limited with a small shell wrapper:

```sh
# ~/bin/zoxide-add-debounced
#!/bin/sh
# Only add if last call was more than 2 seconds ago
stamp=/tmp/zoxide_vifm_last
now=$(date +%s)
last=$(cat "$stamp" 2>/dev/null || echo 0)
if [ $((now - last)) -ge 2 ]; then
    echo "$now" > "$stamp"
    zoxide add "$1"
fi
```

Then replace the autocmd with:

```
autocmd DirEnter * !zoxide-add-debounced %d > /dev/null 2>&1 &
```
