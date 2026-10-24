# Natsuna

Natsuna is a simplified fork of [Haruna](https://invent.kde.org/multimedia/haruna), the mpv-based media player from KDE, with more sensible defaults and a cleaner user interface.

It keeps Haruna's playback engine and features, but trims the menus down to what you actually reach for, keeps the controls out of your way, and changes a few defaults that tend to surprise people. A handful of familiar conventions, like the menu layout and keyboard shortcuts, are borrowed from VLC.

Natsuna installs alongside Haruna. It has its own name, app-menu entry, binary (`natsuna`) and settings (`~/.config/natsuna/`), so the two never interfere.

## What's different from Haruna

### Sensible defaults

- **Clicking the video does nothing.** No more accidental pauses.
- **Double-click toggles fullscreen** cleanly, without a pause/play flicker.
- **Middle click plays/pauses.**
- **The playlist only opens when you ask for it.** It no longer slides out when the mouse touches the edge of the window. Use Ctrl+L or View → Playlist.
- If you do set a single-click action yourself, it waits out the double-click interval, so a double-click never also triggers it.

### A cleaner interface

**Control bar.** A fixed bar under the video:
- Elapsed time sits left of the seek bar, total time on the right. Click the total time to switch to remaining time; your choice is remembered.
- Below that are Play/Pause, Previous, Stop, Next and Fullscreen, with volume on the right.

**Fullscreen controller.** In fullscreen the controls shrink to a smaller box centred at the bottom edge of the screen. It appears when you move the mouse and fades out shortly after the mouse stops.

**File title.** When a file starts, its name is shown for a few seconds at the bottom of the video, with no background box.

**Simpler menus.** One menu bar in a familiar order:

| Menu | Contents |
|---|---|
| Media | Open File, Open Network Stream, Open Recent Media, Quit |
| Playback | Chapter, Speed, Jump Forward/Backward, Play/Pause, Stop, Previous, Next |
| Audio | Audio Track, Increase/Decrease Volume, Mute |
| Video | Zoom, Deinterlace, Take Snapshot |
| Subtitle | Add Subtitle File, Sub Track |
| Tools | Customize Shortcuts, Preferences |
| View | Playlist, Fullscreen, Auto-hide Interface, Always on Top |
| Help | About, Report a Bug, Support Haruna Development |

The right-click menu on the video uses the same menus.

Haruna's more specialised extras are no longer in the menus:
- secondary subtitles, A–B loop, rotation and panning
- subtitle size and position, frame stepping, the transcript panel

They all still work through their keyboard shortcuts, and you can find and rebind every one under **Tools → Preferences → Shortcuts**. Secondary subtitles are also still available from the toolbar's subtitle button.

**Preferences.** The settings window has been rebuilt and renamed Preferences:
- Every page uses the same layout: grouped cards with the setting on the left and its control on the right, so nothing jumps around between pages.
- Options that depend on another one are indented under it and greyed out when they don't apply.
- Pages, in order: General, Playback, Audio, Video, Subtitles, Playlist, Input, Custom Commands, Database, Debug and About.
- **Input** combines Haruna's Shortcuts and Mouse pages: a searchable list of keyboard shortcuts, and the mouse button actions with buttons to change, remove or add them.

**Logo.** Natsuna has its own icon in the same dark, flat style as Haruna's: a light "N" made of film strip on a charcoal tile (*natsu* means summer, a nod to Haruna's *haru*, spring). The same film-strip "N" is shown when nothing is playing, with its sprocket holes sliding while a stream loads.

**Auto-hide interface.** View → Auto-hide Interface (Ctrl+H) hides the menu bar, toolbar and control bar a couple of seconds after the mouse stops moving, so only the video shows. It's handy with Always on Top for keeping a small video over other windows. Move the mouse over the player and everything fades back in, drawn over the video, so the picture never jumps or resizes. The controls stay up while you're using a menu. The window's title bar and frame are hidden too (like KDE's "No Titlebar and Frame"). Drag the video or the top strip to move the window, and drag any edge or corner to resize it. It's also in Preferences → General and is remembered between sessions.

**Always on Top.** View → Always on Top keeps the player above other windows, including a focused fullscreen video or game. On KDE Plasma it uses KWin's "Keep Above Others" together with a window rule that puts the player in KWin's Overlay layer (you'll see it as "Natsuna: Always on Top" under System Settings → Window Rules while it's on). It works on Wayland and X11, and it's remembered between sessions.

### Keyboard shortcuts

| Key | Action |
|---|---|
| Space | Play / pause |
| F | Fullscreen |
| Esc | Leave fullscreen |
| ← / → | Seek |
| Ctrl+← / Ctrl+→ | Big seek |
| ↑ / ↓ | Volume |
| M | Mute |
| N / P | Next / previous file |
| S | Stop |
| Shift+S | Screenshot |
| V / Shift+V | Next / previous subtitle track |
| B / Shift+B | Next / previous audio track |
| L | A–B loop |
| Ctrl+H | Auto-hide interface on / off |
| Ctrl+L | Show / hide playlist |
| Ctrl+N | Open network stream |
| Ctrl+P | Preferences |

All shortcuts and mouse actions can be changed under **Tools → Preferences → Input**. The menu bar can be hidden under Preferences → General (or with Ctrl+M).

## Building

Natsuna needs the same dependencies as Haruna: Qt ≥ 6.9, KDE Frameworks ≥ 6.24, mpv/MpvQt and FFmpeg, plus `extra-cmake-modules` to build. On a current KDE Plasma distro (Arch, openSUSE Tumbleweed, KDE neon, recent Fedora), installing Haruna's build dependencies is enough.

```bash
git clone https://github.com/TormStorm/Natsuna.git
cd Natsuna
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build -j"$(nproc)"

./build/bin/natsuna            # run without installing
cmake --install build          # or install to ~/.local (adds it to the app menu)
```

To update later, run `git pull` and the `cmake --build` line again.

## Keeping up to date with Haruna

Natsuna's changes sit in a small number of commits on top of Haruna, and most of them live in their own files (`src/qml/Natsuna/`, `src/natsuna/`), so Haruna's updates usually merge in cleanly.

**On GitHub:** open the repository page and click **Sync fork → Update branch**.

**From the command line:**

```bash
git remote add upstream https://invent.kde.org/multimedia/haruna.git   # once
git fetch upstream
git merge upstream/master
git push
```

If a merge conflicts, it will almost always be in one of these files:
- the control bar (`src/qml/Footer.qml`)
- the preferences pages (`src/qml/Settings/`), which Natsuna rebuilt
- shortcut and mouse defaults
- the renamed app identity

Keep Haruna's new code and re-apply the Natsuna change.

## Credits and license

Natsuna stands on Haruna, by George Florea Bănuș and the KDE community; nearly all of the real work is theirs. Natsuna is distributed under the same GPL-3.0-or-later license. Please report Natsuna-specific issues here rather than to KDE.
