#include "std.mi"
#include "config.mi"
#include "size.mi"
Global Group root;
Global Layout mainLayout;
Global Container mainOwner;
Global Int nativeScale;
Global Int displayReady, displayActive;
Global String artSuffix;
Global Button playPause, libraryButton, closeButton, minimizeButton;
Global Layer transportGlyph;
Global Int transportPlaying, transportStopSince;
Global Int lastWindowActive;
Global Button menuPlaylist, menuLibrary, menuEqualizer, menuVideo, menuVisualization;
Global Button menuShuffle;
Global ConfigAttribute repeatMode;
Global GuiObject muteButton, dragArea;
Global Group lcdGroup;
Global GuiObject seekTrack, seeker, emptyLogo;
Global Int lcdHasTrack;
Global Int lastElapsedSecond, lastRemainingSecond, lastSeekWidth, lastSeekVisible, lastCapVisible;
Global Int adjustingSize, settledWidth, resizeAnchorWidth;
Global Text titleText, detailText, elapsedText, remainingText;
Global Layer seekFill, seekFillCap;
Global Timer clockTimer, scrollTimer;
Global Text titleRepeat, detailRepeat;
Global Group titleViewport, detailViewport;
Global Double scrollPhase;
Global Int scrollRestMs, scrollLastTime, scrollTitleWidth, scrollDetailWidth, scrollViewWidth;
Global Int savedVolume;
Function Int px(Int logical);
Function setPlayerSize(Int percent);
Function activateDisplay();
Function initializeEqualizer();
Function updateWindowFocus();
Function setTrafficImages(Button control, String prefix);
Function updateTrack();
Function updateDisplay(Int width);
Function setDisplayWidth(Int width);
Function updateTime();
Function resetTimeCache();
Function updateTransport();
Function updateLcdState();
Function String formatClock(Int milliseconds);
Function togglePlayback();
Function showMenu();
Function resetScroll();
Function scrollTick();
Function renderScrollLine(Text primary, Text repeated, Group viewport, Double phase);

System.onScriptLoaded() {
 displayReady = 0; displayActive = 0;
 nativeScale = stringToInteger(getParam());
 if (nativeScale != 1 && nativeScale != 2 && nativeScale != 4) nativeScale = 1;
 artSuffix = "";
 if (nativeScale != 1) artSuffix = "." + integerToString(nativeScale) + "x";
 root = getScriptGroup();
 mainLayout = root.getParentLayout();
 mainOwner = mainLayout.getContainer();
 initializeEqualizer();
 playPause = root.findObject("playpause");
 transportGlyph = root.findObject("transport.status");
 transportPlaying = -1; transportStopSince = -1;
 muteButton = root.findObject("mute");
 titleText = root.findObject("track.title");
 detailText = root.findObject("track.detail");
 elapsedText = root.findObject("time.elapsed");
 remainingText = root.findObject("time.remaining");
 seekFill = root.findObject("seek.fill");
 seekFillCap = root.findObject("seek.fill.cap");
 libraryButton = root.findObject("library");
 closeButton = root.findObject("close");
 minimizeButton = root.findObject("minimize");
 lastWindowActive = -1;
 updateWindowFocus();
 menuShuffle = root.findObject("menu.shuffle");
 ConfigItem playbackOptions = Config.getItemByGuid("{45F3F7C1-A6F3-4EE6-A15E-125E92FC3F8D}");
 repeatMode = playbackOptions.getAttribute("Repeat");
 menuPlaylist = root.findObject("menu.open.pl");
 menuLibrary = root.findObject("menu.open.ml");
 menuEqualizer = root.findObject("menu.open.eq");
 menuVideo = root.findObject("menu.open.vid");
 menuVisualization = root.findObject("menu.open.avs");
 dragArea = root.findObject("drag");
 lcdGroup = root.findObject("mini.lcd" + artSuffix);
 seekTrack = root.findObject("seek.track");
 seeker = root.findObject("seek");
 emptyLogo = root.findObject("lcd.empty.logo");
 lcdHasTrack = -1;
 titleRepeat = root.findObject("track.title.repeat");
 detailRepeat = root.findObject("track.detail.repeat");
 titleViewport = root.findObject("track.title.viewport" + artSuffix);
 detailViewport = root.findObject("track.detail.viewport" + artSuffix);
 scrollPhase = 0; scrollRestMs = 2000; scrollLastTime = getTimeOfDay();
 scrollTimer = new Timer;
 scrollTimer.setDelay(17);
 scrollTimer.start();
 adjustingSize = 0;
 savedVolume = getPrivateInt("iTunes MiniPlayer", "volume.saved", 180);
 clockTimer = new Timer;
 clockTimer.setDelay(17);
 clockTimer.start();
 // A hidden layout may be initialized before it is ever shown. It must not
 // resize the player's active window or treat hidden geometry as live state.
 settledWidth = mainLayout.getWidth();
 resizeAnchorWidth = settledWidth;
 displayReady = 1;
 activateDisplay();
}
activateDisplay() {
 if (!displayReady) return;
 if (mainOwner.getCurLayout() != mainLayout || !mainLayout.isVisible()) return;
 displayActive = 1;
 // Returning to an existing layout is not another onScriptLoaded. Re-arm its
 // timers and read live playback state rather than retaining its old display.
 clockTimer.start(); scrollTimer.start();
 lcdHasTrack = -1; lastWindowActive = -1;
 setDisplayWidth(mainLayout.getWidth());
 updateTrack(); updateTime(); updateWindowFocus(); updateTransport();
}
mainOwner.onSwitchToLayout(Layout nextLayout) {
 if (nextLayout == mainLayout) activateDisplay();
 else displayActive = 0;
}
mainLayout.onSetVisible(Boolean visible) {
 if (visible) activateDisplay();
 else displayActive = 0;
}
// All geometry follows this layout's native pixel grid; playback units do not.
Int px(Int logical) { return logical * nativeScale; }
setPlayerSize(Int percent) {
 if (percent != 100 && percent != 200 && percent != 400) percent = 100;
 setPrivateInt("iTunes MiniPlayer", "player.layout.size", percent);
 Int factor = percent / 100;
 // Only the main player changes size; auxiliary windows keep their 1x layout.
 // Playback belongs to the host and is never restarted.
 switchWindowSize(mainOwner, factor);
}
System.onScriptUnloading() { clockTimer.stop(); delete clockTimer; scrollTimer.stop(); delete scrollTimer; }
System.onTitleChange(String newTitle) { updateTrack(); updateTime(); }
System.onPlay() { updateTrack(); updateTime(); updateTransport(); }
System.onStop() { updateTrack(); updateTime(); updateTransport(); }
System.onPause() { updateTime(); updateTransport(); }
System.onResume() { updateTime(); updateTransport(); }
System.onSeek(int newpos) { updateTime(); }
clockTimer.onTimer() {
 // Inactive layout instances must not resize or animate the current player.
 if (mainOwner.getCurLayout() != mainLayout || !mainLayout.isVisible()) {
  displayActive = 0;
  return;
 }
 if (!displayActive) activateDisplay();
 // Compare like units and integer types. MAKI division produces a real even
 // for 100 / 100; comparing percentages avoids a mixed numeric comparison.
 if (readPlayerSize() != nativeScale * 100) {
  setPlayerSize(readPlayerSize());
  return;
 }
 updateTime(); updateWindowFocus(); updateTransport();
}
updateTransport() {
 Int playbackState = getStatus();
 Int playing = (playbackState == 1);
 // A stop/play pair between files must not flash the play triangle. Only
 // commit a stopped icon after a continuous 250ms stop; pause is immediate.
 if (playbackState == 0 && transportPlaying == 1) {
  Int now = getTimeOfDay();
  if (transportStopSince < 0) transportStopSince = now;
  Int stoppedFor = now - transportStopSince;
  if (stoppedFor < 0) stoppedFor = stoppedFor + 86400000;
  if (stoppedFor < 250) return;
 } else transportStopSince = -1;
 if (playing == transportPlaying) return;
 transportPlaying = playing;
 if (playing) transportGlyph.setXmlParam("image", "mini.glyph-pause" + artSuffix);
 else transportGlyph.setXmlParam("image", "mini.glyph-play" + artSuffix);
}
initializeEqualizer() {
 // Start this version flat once, then retain the listener's later adjustments.
 if (getPrivateInt("iTunes MiniPlayer", "eq.flat.initialized", 0)) return;
 setEqPreamp(0);
 for (Int band = 0; band < 10; band++) setEqBand(band, 0);
 setPrivateInt("iTunes MiniPlayer", "eq.flat.initialized", 1);
}
updateWindowFocus() {
 Int active = mainLayout.isActive();
 if (active == lastWindowActive) return;
 lastWindowActive = active;
 if (active) {
  setTrafficImages(closeButton, "mini.close");
  setTrafficImages(minimizeButton, "mini.minimize");
  setTrafficImages(libraryButton, "mini.library");
 } else {
  setTrafficImages(closeButton, "");
  setTrafficImages(minimizeButton, "");
  setTrafficImages(libraryButton, "");
 }
}
setTrafficImages(Button control, String prefix) {
 if (prefix == "") {
  control.setXmlParam("image", "mini.close-inactive" + artSuffix);
  control.setXmlParam("hoverImage", "mini.close-inactive" + artSuffix);
  control.setXmlParam("downImage", "mini.close-inactive" + artSuffix);
 } else {
  control.setXmlParam("image", prefix + "-normal" + artSuffix);
  control.setXmlParam("hoverImage", prefix + "-hover" + artSuffix);
  control.setXmlParam("downImage", prefix + "-down" + artSuffix);
 }
}

updateTrack() {
 String trackName = getPlayItemMetaDataString("title");
 String artistName = getPlayItemMetaDataString("artist");
 String albumName = getPlayItemMetaDataString("album");
 if (trackName == "") trackName = getPlayItemDisplayTitle();
 if (getPlayItemString() == "") trackName = "";
 titleText.setText(trackName); titleRepeat.setText(trackName);
 String detail = artistName;
 if (albumName != "") {
  if (detail != "") detail = detail + " - ";
  detail = detail + albumName;
 }
 if (getPlayItemString() == "") detail = "";
 detailText.setText(detail); detailRepeat.setText(detail);
 resetScroll();
}
updateLcdState() {
 // An empty playlist differs from a loaded track that is merely stopped.
 Int hasTrack = (getPlayItemString() != "");
 if (hasTrack == lcdHasTrack) return;
 lcdHasTrack = hasTrack;
 resetTimeCache();
 if (hasTrack) {
  emptyLogo.hide();
  titleViewport.show(); detailViewport.show();
  elapsedText.show(); remainingText.show();
  seekTrack.show(); seeker.show();
 } else {
  titleViewport.hide(); detailViewport.hide();
  elapsedText.hide(); remainingText.hide();
  seekTrack.hide(); seeker.hide();
  seekFill.hide(); seekFillCap.hide();
  emptyLogo.show();
 }
 updateTrack();
}
resetTimeCache() {
 lastElapsedSecond = -2; lastRemainingSecond = -2;
 lastSeekWidth = -1; lastSeekVisible = -1; lastCapVisible = -1;
}
updateTime() {
 updateLcdState();
 if (!lcdHasTrack) return;
 Int length = getPlayItemLength();
 Int position = getPosition();
 if (getStatus() == 0 || position < 0) position = 0;
 if (length > 0 && position > length) position = length;
 // Quantize the shared playback sample once. Independently truncating
 // length-position makes the remaining clock tick between elapsed ticks.
 Int elapsedSecond = position / 1000;
 Int remainingSecond = -1;
 if (length > 0) {
  Int durationSecond = length / 1000;
  remainingSecond = durationSecond - elapsedSecond;
  if (remainingSecond < 0) remainingSecond = 0;
 }
 // Publish a pair on the same callback, including duration/stream changes.
 if (elapsedSecond != lastElapsedSecond || remainingSecond != lastRemainingSecond) {
  elapsedText.setText(formatClock(elapsedSecond * 1000));
  if (remainingSecond >= 0) remainingText.setText("-" + formatClock(remainingSecond * 1000));
  else remainingText.setText("");
  lastElapsedSecond = elapsedSecond; lastRemainingSecond = remainingSecond;
 }
 Int width = 0;
 Int fillVisible = (length > 0);
 if (length > 0) {
  Int available = mainLayout.getWidth() - px(222);
  if (available < 0) available = 0;
  Double fraction = position;
  fraction = fraction / length;
  // Align the filled section with the inset native diamond center.
  width = fraction * (available - px(3)) + px(1);
  if (width > available) width = available;
  if (width < 0) width = 0;
 }
 if (width != lastSeekWidth) {
  seekFill.setXmlParam("w", integerToString(width));
  lastSeekWidth = width;
 }
 if (fillVisible != lastSeekVisible) {
  if (fillVisible) seekFill.show(); else seekFill.hide();
  lastSeekVisible = fillVisible;
 }
 Int capVisible = (fillVisible && width > 0);
 if (capVisible != lastCapVisible) {
  if (capVisible) seekFillCap.show(); else seekFillCap.hide();
  lastCapVisible = capVisible;
 }
}
togglePlayback() {
 if (getStatus() == 1) pause();
 else play();
}
playPause.onLeftClick() { togglePlayback(); }
muteButton.onLeftButtonUp(int x, int y) {
 if (getVolume() > 0) {
  savedVolume = getVolume();
  setPrivateInt("iTunes MiniPlayer", "volume.saved", savedVolume);
  setVolume(0);
 }
 else setVolume(getPrivateInt("iTunes MiniPlayer", "volume.saved", savedVolume));
}
libraryButton.onLeftClick() { showMenu(); }
dragArea.onLeftButtonDblClk(int x, int y) {
 if (mainLayout.getWidth() <= px(112)) setDisplayWidth(px(312));
 else setDisplayWidth(px(112));
}
setDisplayWidth(Int width) {
 if (width > px(112) && width < px(250)) width = px(112);
 // Explicit restores and startup set a fresh baseline, outside drag snapping.
 adjustingSize = 1;
 resizeAnchorWidth = width;
 mainLayout.resize(mainLayout.getLeft(), mainLayout.getTop(), width, px(58));
 adjustingSize = 0;
 updateDisplay(width);
}
mainLayout.onResize(int x, int y, int w, int h) {
 if (!displayReady || mainOwner.getCurLayout() != mainLayout || !mainLayout.isVisible()) return;
 if (adjustingSize) return;
 Int target = w;
 // Track raw native drag widths separately from the snapped window width.
 // The host retains the original mouse anchor throughout the drag.
 if (w <= px(112)) {
  target = px(112); resizeAnchorWidth = px(112);
 } else if (w < px(250)) {
  if (settledWidth <= px(112)) {
   if (w < resizeAnchorWidth) resizeAnchorWidth = w;
   if (w >= resizeAnchorWidth + px(6)) {
    target = px(250); resizeAnchorWidth = w;
   } else target = px(112);
  } else {
   if (resizeAnchorWidth >= px(250)) {
    target = px(112); resizeAnchorWidth = w;
   } else {
    // After an early reveal, keep the LCD visible as the pointer catches up.
    if (w > resizeAnchorWidth) resizeAnchorWidth = w;
    if (w <= resizeAnchorWidth - px(6)) {
     target = px(112); resizeAnchorWidth = w;
    } else target = px(250);
   }
  }
 } else {
  resizeAnchorWidth = w;
  // A small magnetic target around the standard width, escapable both ways.
  if (w >= px(302) && w <= px(322)) target = px(312);
 }
 if (target != w) {
  adjustingSize = 1;
  mainLayout.resize(x, y, target, px(58));
  adjustingSize = 0;
 }
 updateDisplay(target);
}
updateDisplay(Int width) {
 settledWidth = width;
 if (width < px(250)) { lcdGroup.hide(); return; }
 lcdGroup.show();
 Int logoX = (width - px(122) - px(19)) / 2;
 emptyLogo.setXmlParam("x", integerToString(logoX));
 titleViewport.setXmlParam("x", integerToString(px(9))); titleViewport.setXmlParam("w", integerToString(px(-18)));
 detailViewport.setXmlParam("x", integerToString(px(9))); detailViewport.setXmlParam("w", integerToString(px(-18)));
 seeker.setXmlParam("x", integerToString(px(48))); seeker.setXmlParam("w", integerToString(px(-97)));
 seekTrack.setXmlParam("x", integerToString(px(48))); seekTrack.setXmlParam("w", integerToString(px(-96)));
 seekFill.setXmlParam("x", integerToString(px(50)));
 seekFillCap.setXmlParam("x", integerToString(px(48)));
 resetScroll();
 updateTime();
}
showMenu() {
 // Winamp's real repeat setting: 0 = off, 1 = all, -1 = one.
 Int repeat = stringToInteger(repeatMode.getData());
 PopupMenu popup = new PopupMenu;
 popup.addCommand("Playlist", 1, isNamedWindowVisible("guid:pl"), 0);
 popup.addCommand("Media Library", 2, isNamedWindowVisible("guid:ml"), 0);
 popup.addCommand("Equalizer", 3, isNamedWindowVisible("guid:eq"), 0);
 popup.addCommand("Video", 4, isNamedWindowVisible("guid:vid"), 0);
 popup.addCommand("Visualization", 5, isNamedWindowVisible("guid:avs"), 0);
 popup.addSeparator();
 popup.addCommand("Shuffle", 21, menuShuffle.getActivated(), 0);
 popup.addCommand("Repeat One", 23, repeat == -1, 0);
 popup.addCommand("Repeat All", 22, repeat == 1, 0);
 popup.addSeparator();
 Int size = readPlayerSize();
 popup.addCommand("1x size", 31, size == 100, 0);
 popup.addCommand("2x size", 32, size == 200, 0);
 popup.addCommand("4x size", 33, size == 400, 0);
 popup.addSeparator();
 Int font = getPrivateInt("iTunes MiniPlayer", "display.font", 0);
 if (font != 1) font = 0;
 popup.addCommand("Lucida Grande (osx default)", 51, font == 0, 0);
 popup.addCommand("DejaVu Sans (backup)", 52, font == 1, 0);
 Int command = popup.popAtMouse();
 delete popup;
 if (command == 1) menuPlaylist.leftClick();
 if (command == 2) menuLibrary.leftClick();
 if (command == 3) menuEqualizer.leftClick();
 if (command == 4) menuVideo.leftClick();
 if (command == 5) menuVisualization.leftClick();
 if (command == 21) menuShuffle.leftClick();
 if (command == 31) setPlayerSize(100);
 if (command == 32) setPlayerSize(200);
 if (command == 33) setPlayerSize(400);
 if (command == 51) setPrivateInt("iTunes MiniPlayer", "display.font", 0);
 if (command == 52) setPrivateInt("iTunes MiniPlayer", "display.font", 1);
 // Selecting the checked mode turns repeat off. Read again after the popup
 // closes so a host-side change during menu tracking is respected.
 repeat = stringToInteger(repeatMode.getData());
 if (command == 22) {
  if (repeat == 1) repeatMode.setData("0");
  else repeatMode.setData("1");
 }
 if (command == 23) {
  if (repeat == -1) repeatMode.setData("0");
  else repeatMode.setData("-1");
 }
}

// Reconstructed synchronized marquee: 15 px/s, one pass per row, then wait.
// Exact historical Apple timing is not documented; use a two-second rest.
scrollTimer.onTimer() {
 if (mainOwner.getCurLayout() == mainLayout && mainLayout.isVisible()) scrollTick();
}
resetScroll() {
 scrollPhase = 0;
 scrollRestMs = 2000;
 scrollLastTime = getTimeOfDay();
 scrollTitleWidth = titleText.getTextWidth();
 scrollDetailWidth = detailText.getTextWidth();
 scrollViewWidth = titleViewport.getWidth();
 renderScrollLine(titleText, titleRepeat, titleViewport, 0);
 renderScrollLine(detailText, detailRepeat, detailViewport, 0);
}
scrollTick() {
 Int now = getTimeOfDay();
 Int delta = now - scrollLastTime;
 scrollLastTime = now;
 // Ignore clock jumps, midnight rollover and long stalls rather than jumping
 // the text. Ordinary timer jitter still advances at exactly 15 pixels/s.
 if (delta < 0 || delta > 250) delta = 0;
 if (mainLayout.getWidth() <= px(112)) return;
 if (titleText.getTextWidth() != scrollTitleWidth || detailText.getTextWidth() != scrollDetailWidth || titleViewport.getWidth() != scrollViewWidth) {
  resetScroll();
  return;
 }
 if (scrollRestMs > 0) {
  if (delta <= scrollRestMs) { scrollRestMs = scrollRestMs - delta; delta = 0; }
  else { delta = delta - scrollRestMs; scrollRestMs = 0; }
 }
 Int longestCycle = 0;
 if (scrollTitleWidth > scrollViewWidth) longestCycle = scrollTitleWidth + px(40);
 if (scrollDetailWidth > scrollViewWidth && scrollDetailWidth + px(40) > longestCycle) longestCycle = scrollDetailWidth + px(40);
 if (longestCycle == 0) scrollPhase = 0;
 else scrollPhase = scrollPhase + delta * 0.015 * px(1);
 if (longestCycle > 0 && scrollPhase >= longestCycle) {
  scrollPhase = 0;
  scrollRestMs = 2000;
 }
 renderScrollLine(titleText, titleRepeat, titleViewport, scrollPhase);
 renderScrollLine(detailText, detailRepeat, detailViewport, scrollPhase);
}
renderScrollLine(Text primary, Text repeated, Group viewport, Double phase) {
 Int textWidth = primary.getTextWidth();
 Int viewWidth = viewport.getWidth();
 if (textWidth <= viewWidth) {
  primary.setXmlParam("x", "0");
  primary.setXmlParam("w", integerToString(viewWidth));
  primary.setXmlParam("align", "center");
  repeated.hide();
  return;
 }
 Int cycle = textWidth + px(40);
 Int offset = phase;
 // A finished row rests at its beginning while the other row catches up.
 if (phase >= cycle) offset = 0;
 primary.setXmlParam("align", "left");
 primary.setXmlParam("w", integerToString(textWidth));
 primary.setXmlParam("x", integerToString(0 - offset));
 repeated.setXmlParam("w", integerToString(textWidth));
 repeated.setXmlParam("x", integerToString(cycle - offset));
 if (offset == 0) repeated.hide(); else repeated.show();
}

// Format the millisecond playback clock ourselves: hosts disagree about
// integerToTime's input unit, so passing through it can divide twice.
String formatClock(Int milliseconds) {
 if (milliseconds < 0) milliseconds = 0;
 Int seconds = milliseconds / 1000;
 Int minutes = seconds / 60;
 seconds = seconds - minutes * 60;
 String result = integerToString(minutes) + ":";
 if (seconds < 10) result = result + "0";
 return result + integerToString(seconds);
}
