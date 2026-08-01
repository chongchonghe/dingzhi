# Vifm Music Player Guide

## Quick Start

1. **Start mpd daemon**:
   ```bash
   mpd
   ```

2. **Start vifm in music mode**:
   ```bash
   vifm --session music
   ```

3. **Navigate to your music files** and start playing!

## Key Mappings

### Basic Playback Controls
- `p` - Play/Pause toggle
- `>` - Next song
- `<` - Previous song
- `gS` - Stop playback
- `w` - Show current song

### Volume Control
- `+` - Volume up (+2)
- `-` - Volume down (-2)

### Adding Songs to Playlist
- `a` - Add current file to playlist
- `A` - Add all selected files to playlist
- `C` - Clear entire playlist
- `c` - Crop playlist (keep only current song)

### Playlist Management
- `L` - List current playlist
- `j` - Play specific song from playlist (with fuzzy finder)
- `P` - Find and play song from playlist
- `D` - Delete current song from playlist
- `dp` - Delete specific song from playlist (with fuzzy finder)
- `x` - Shuffle playlist
- `E` - Edit playlist in text editor

### Seeking and Navigation
- `I` - Seek forward 5 seconds
- `K` - Seek backward 5 seconds
- `s1` through `s9` - Seek to 10%, 20%, ... 90% of song
- `sg` - Go to beginning of song
- `<C-g>` - Go to currently playing file in vifm

### Playback Modes
- `R` - Toggle repeat mode
- `X` - Toggle random mode
- `S` - Toggle single mode (play one song and stop)

### Status and Information
- `q` - Show detailed status (volume, repeat, random, single)
- `o` - Show current line from mpc status

## Workflow Example

1. **Setup**:
   ```bash
   # Start mpd
   mpd
   
   # Start vifm in music mode
   vifm --session music
   ```

2. **Navigate to music**: Use normal vifm navigation to browse your music files

3. **Build playlist**:
   - Select songs/albums and press `a` to add them
   - Or press `A` to add all selected files at once

4. **Start playing**:
   - Press `p` to start playback
   - Use `>` and `<` to navigate between songs

5. **Control playback**:
   - Adjust volume with `+` and `-`
   - Use `j` to jump to specific songs
   - Press `w` to see what's currently playing

## Advanced Features

### Playlist Editor
- Press `E` to edit the current playlist in your text editor
- The script will maintain playback position when you save changes
- Requires Python 3 with `python-mpd2` package

### Fuzzy Finding
- `P` and `j` use fzf for fuzzy finding songs in your playlist
- Type part of a song name to quickly find it

### File Management
- All normal vifm commands work in music mode
- You can still copy, move, and organize your music files

## Troubleshooting

### MPD not connecting
- Check if mpd is running: `ps aux | grep mpd`
- Test mpc connection: `mpc status`
- Check mpd log: `tail ~/.mpd/log`

### No audio output
- Check mpd configuration for audio output settings
- Verify system audio is working
- Check mpc volume: `mpc volume`

### Fuzzy finder not working
- Install fzf: `brew install fzf`
- Or switch back to dmenu in vifmrc

## Tips

- Use tab completion for commands like `:pls` (save playlist) and `:pll` (load playlist)
- You can save playlists with `:pls playlistname`
- Load saved playlists with `:pll playlistname`
- Press `q` regularly to check your playback modes and volume
- Use `w` to remind yourself what's currently playing 