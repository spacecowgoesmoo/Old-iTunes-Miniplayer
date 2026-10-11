iTunes MiniPlayer v1.39
======================
A refined Winamp Modern (.wal) skin based on the classic iTunes MiniPlayer.
Default size: 312 x 58. Maximum width: 400. Collapsed size: 112 x 58.

INSTALL
Winamp: open the .wal with Winamp or copy it into Winamp/Skins.
NullPlayer: Skins > Modern > Load Skin..., then select the .wal.
The .wal contains everything required; no extraction is necessary.
Winamp 5.66+ with Modern Skin Support or a compatible Modern skin engine
is required. Lucida Grande is used where installed, with Tahoma as the
alternate font. Fonts are provided by the operating system.
Inactive traffic lights follow this window's focus.

WHAT CHANGED
- The second LCD text row stays blank when artist and album tags are absent.
  Artist-only and album-only tags still display without a separator; both
  display as Artist - Album. The first row retains the file-title fallback.

COMPATIBILITY NOTES
Skin-driven scrolling and progress updates request a 17ms interval (about
60Hz). Timer delivery and painting depend on the player. Whole-pixel text
positions do not promise 60 distinct visible positions per second at low DPI.
Native visualizations and dragging follow host timing.
NullPlayer coerces Repeat One into Repeat All. Its unwanted native edge/stuck
cursors require host fixes. This skin does not modify NullPlayer.

RESIZING
Grab the rightmost six pixels of the frame and drag horizontally. Pull the
edge right a little to restore the LCD. Double-click the silver frame to collapse
or restore immediately. Below 250px, the entire LCD disappears and the
player snaps to 112px. With a track loaded, every expanded width retains
elapsed and remaining time labels.

CONTROLS
Red light: close. Yellow light: minimize. Green light: extra Winamp windows, Shuffle, Repeat One, and Repeat All,
even when collapsed.
Previous / center / next: previous track, play/pause, next track.
Small speaker: mute/restore. Bottom slider: volume.
LCD bottom slider: seek.
Drag LCD text or any unused main-window area to move the player.
Double-click track text: file information. Drop music onto the player to play.
Shuffle toggles independently. Repeat All and Repeat One are mutually exclusive;
select the checked repeat mode to turn repeat off.
Streams with unknown length do not show remaining time.

EDITING
skin.xml: layouts and resources. assets/: original PNG interface artwork.
scripts/miniplayer.m: editable MAKI source. scripts/miniplayer.maki: native
compiled script. standardframe.m/.maki implement the reusable Winamp frame.
To recompile, place the Winamp SDK std.mi and config.mi beside the
source and run Nullsoft mc.exe for each .m file. SDK/compiler not bundled.
The skin does not reference another skin's directory.
build_artwork.py and build_subwindows.py regenerate the source artwork/XML;
package_skin.py produces the .wal. build_reference holds the original
auxiliary-frame input used by the artwork builder.

Unofficial fan-made skin, created with Codex.
