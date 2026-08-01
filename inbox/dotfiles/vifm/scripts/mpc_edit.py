#!/usr/bin/env python3

import os
import tempfile
from mpd import MPDClient

# Options
editor = os.environ.get('EDITOR', 'vim')
# Amount (in seconds) to rewind when reloading the playlist
setback = 4

# Startup
client = MPDClient()
client.connect("localhost", 6600)

with tempfile.NamedTemporaryFile('w+') as tmpf:
    tmpf.writelines((song['file']+'\n' for song in client.playlistid()))
    tmpf.seek(0)
    old_playlist = [song.strip() for song in tmpf.readlines()]
    # Ensure that the file has been written to disk
    tmpf.flush()
    os.system("{} {}".format(editor, tmpf.name))
    tmpf.seek(0)
    new_playlist = [song.strip() for song in tmpf.readlines()]

if new_playlist != old_playlist:
    # Save the status right before we change things:
    current_song = client.currentsong().get('file', '')
    elapsed = float(client.status().get('elapsed', 0))

    client.clear()
    for song in new_playlist:
        if song.strip():  # Skip empty lines
            client.add(song)

    # Check if the song we were listening to is in the new playlist
    try:
        new_pos = [song['file'] for song in
                client.playlistid()].index(current_song)
    except ValueError:
        pass
    else:
        client.seek(new_pos, elapsed-setback if elapsed>setback else 0)

client.close()
client.disconnect()

