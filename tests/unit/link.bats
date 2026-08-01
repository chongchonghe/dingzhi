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

@test "links a directory, and relinking is a no-op" {
    mkdir -p "$HOME/src/dir"
    echo x > "$HOME/src/dir/inner"
    manage_symlink "$HOME/src/dir" "$HOME/.config/thing" "a directory"
    [ -L "$HOME/.config/thing" ]
    [ -f "$HOME/.config/thing/inner" ]
    run manage_symlink "$HOME/src/dir" "$HOME/.config/thing" "a directory"
    [[ "$output" == *"already linked"* ]]
}

@test "relinking a directory does not nest the link inside itself" {
    # ln -s without -n would create ~/.config/thing/dir on the second call.
    mkdir -p "$HOME/src/dir"
    manage_symlink "$HOME/src/dir" "$HOME/.config/thing" "a directory"
    manage_symlink "$HOME/src/dir" "$HOME/.config/thing" "a directory"
    [ ! -e "$HOME/.config/thing/dir" ]
}

@test "a relative symlink pointing at the right target is recognised" {
    ln -s "src/file" "$HOME/dest"
    run manage_symlink "$HOME/src/file" "$HOME/dest" "test file"
    [[ "$output" == *"already linked"* ]]
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

@test "link_summary reports backups" {
    echo "precious" > "$HOME/dest"
    manage_symlink "$HOME/src/file" "$HOME/dest" "test file"
    run link_summary
    [[ "$output" == *"backed up"* ]]
}

@test "link.sh passes shellcheck" {
    run shellcheck -s bash -e SC1091 "$DINGZHI_PATH/lib/link.sh"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}
