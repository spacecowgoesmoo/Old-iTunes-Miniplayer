#include "std.mi"
#include "config.mi"
Global Group root;
Global Layout mainLayout;
Global Button playPause, libraryButton, closeButton, minimizeButton;
Global Int lastWindowActive;
Global Button menuPlaylist, menuLibrary, menuEqualizer, menuVideo, menuVisualization;
Global Button menuShuffle;
Global ConfigAttribute repeatMode;
Global GuiObject muteButton, dragArea;
Global Group lcdGroup;
Global GuiObject seekTrack, seeker;
Global Int adjustingSize, settledWidth, resizeAnchorWidth;
Global Text titleText, detailText, elapsedText, remainingText;
Global Layer seekFill, seekFillCap;
Global Timer clockTimer, scrollTimer;
Global Text titleRepeat, detailRepeat;
Global Group titleViewport, detailViewport;
Global Double scrollPhase;
Global Int scrollRestMs, scrollLastTime, scrollTitleWidth, scrollDetailWidth, scrollViewWidth;
Global Int savedVolume;
Function initializeEqualizer();
Function updateWindowFocus();
Function setTrafficImages(Button control, String prefix);
Function updateTrack();
Function updateDisplay(Int width);
Function setDisplayWidth(Int width);
Function updateTime();
Function String formatClock(Int milliseconds);
Function togglePlayback();
Function showMenu();
Function resetScroll();
Function scrollTick();
Function renderScrollLine(Text primary, Text repeated, Group viewport, Double phase);

System.onScriptLoaded() {
 root = getScriptGroup();
 mainLayout = root.getParentLayout();
 initializeEqualizer();
 playPause = root.findObject("playpause");
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
 lcdGroup = root.findObject("mini.lcd");
 seekTrack = root.findObject("seek.track");
 seeker = root.findObject("seek");
 titleRepeat = root.findObject("track.title.repeat");
 detailRepeat = root.findObject("track.detail.repeat");
 titleViewport = root.findObject("track.title.viewport");
 detailViewport = root.findObject("track.detail.viewport");
 scrollPhase = 0; scrollRestMs = 2000; scrollLastTime = getTimeOfDay();
 scrollTimer = new Timer;
 scrollTimer.setDelay(17);
 scrollTimer.start();
 adjustingSize = 0;
 savedVolume = 180;
 clockTimer = new Timer;
 clockTimer.setDelay(17);
 clockTimer.start();
 setDisplayWidth(mainLayout.getWidth());
 updateTrack(); updateTime();
}
System.onScriptUnloading() { clockTimer.stop(); delete clockTimer; scrollTimer.stop(); delete scrollTimer; }
System.onTitleChange(String newTitle) { updateTrack(); updateTime(); }
System.onPlay() { updateTrack(); updateTime(); }
System.onStop() { updateTime(); }
System.onPause() { updateTime(); }
System.onResume() { updateTime(); }
System.onSeek(int newpos) { updateTime(); }
clockTimer.onTimer() { updateTime(); updateWindowFocus(); }
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
  control.setXmlParam("image", "mini.close-inactive");
  control.setXmlParam("hoverImage", "mini.close-inactive");
  control.setXmlParam("downImage", "mini.close-inactive");
 } else {
  control.setXmlParam("image", prefix + "-normal");
  control.setXmlParam("hoverImage", prefix + "-hover");
  control.setXmlParam("downImage", prefix + "-down");
 }
}

updateTrack() {
 String trackName = getPlayItemMetaDataString("title");
 String artistName = getPlayItemMetaDataString("artist");
 String albumName = getPlayItemMetaDataString("album");
 if (trackName == "") trackName = getPlayItemDisplayTitle();
 if (trackName == "") trackName = "iTunes MiniPlayer";
 titleText.setText(trackName); titleRepeat.setText(trackName);
 String detail = artistName;
 if (albumName != "") {
  if (detail != "") detail = detail + " - ";
  detail = detail + albumName;
 }
 if (detail == "") {
  if (getPlayItemString() == "") detail = "Drop music here to begin";
  else detail = "Winamp";
 }
 detailText.setText(detail); detailRepeat.setText(detail);
 resetScroll();
}
updateTime() {
 Int length = getPlayItemLength();
 Int position = getPosition();
 if (getStatus() == 0 || position < 0) position = 0;
 if (length > 0 && position > length) position = length;
 elapsedText.setText(formatClock(position));
 if (length > 0) {
  Int remaining = length - position;
  if (remaining < 0) remaining = 0;
  remainingText.setText("-" + formatClock(remaining));
  Int available = mainLayout.getWidth() - 222;
  if (available < 0) available = 0;
  Double fraction = position;
  fraction = fraction / length;
  // Align the filled section with the inset native diamond center.
  Int width = fraction * (available - 3) + 1;
  if (width > available) width = available;
  if (width < 0) width = 0;
  seekFill.setXmlParam("w", integerToString(width));
  if (width > 0) seekFillCap.show(); else seekFillCap.hide();
 } else {
  remainingText.setText("");
  seekFill.setXmlParam("w", "0");
  seekFillCap.hide();
 }
}
togglePlayback() {
 if (getStatus() == 1) pause();
 else play();
}
playPause.onLeftClick() { togglePlayback(); }
muteButton.onLeftButtonUp(int x, int y) {
 if (getVolume() > 0) { savedVolume = getVolume(); setVolume(0); }
 else setVolume(savedVolume);
}
libraryButton.onLeftClick() { showMenu(); }
dragArea.onLeftButtonDblClk(int x, int y) {
 if (mainLayout.getWidth() <= 112) setDisplayWidth(312);
 else setDisplayWidth(112);
}
setDisplayWidth(Int width) {
 if (width > 112 && width < 250) width = 112;
 // Explicit restores and startup set a fresh baseline, outside drag snapping.
 adjustingSize = 1;
 resizeAnchorWidth = width;
 mainLayout.resize(mainLayout.getLeft(), mainLayout.getTop(), width, 58);
 adjustingSize = 0;
 updateDisplay(width);
}
mainLayout.onResize(int x, int y, int w, int h) {
 if (adjustingSize) return;
 Int target = w;
 // Track raw native drag widths separately from the snapped window width.
 // The host retains the original mouse anchor throughout the drag.
 if (w <= 112) {
  target = 112; resizeAnchorWidth = 112;
 } else if (w < 250) {
  if (settledWidth <= 112) {
   if (w < resizeAnchorWidth) resizeAnchorWidth = w;
   if (w >= resizeAnchorWidth + 6) {
    target = 250; resizeAnchorWidth = w;
   } else target = 112;
  } else {
   if (resizeAnchorWidth >= 250) {
    target = 112; resizeAnchorWidth = w;
   } else {
    // After an early reveal, keep the LCD visible as the pointer catches up.
    if (w > resizeAnchorWidth) resizeAnchorWidth = w;
    if (w <= resizeAnchorWidth - 6) {
     target = 112; resizeAnchorWidth = w;
    } else target = 250;
   }
  }
 } else {
  resizeAnchorWidth = w;
  // A small magnetic target around the standard width, escapable both ways.
  if (w >= 302 && w <= 322) target = 312;
 }
 if (target != w) {
  adjustingSize = 1;
  mainLayout.resize(x, y, target, 58);
  adjustingSize = 0;
 }
 updateDisplay(target);
}
updateDisplay(Int width) {
 settledWidth = width;
 if (width < 250) { lcdGroup.hide(); return; }
 lcdGroup.show();
 elapsedText.show(); remainingText.show();
 titleViewport.setXmlParam("x", "14"); titleViewport.setXmlParam("w", "-28");
 detailViewport.setXmlParam("x", "14"); detailViewport.setXmlParam("w", "-28");
 seeker.setXmlParam("x", "48"); seeker.setXmlParam("w", "-97");
 seekTrack.setXmlParam("x", "48"); seekTrack.setXmlParam("w", "-96");
 seekFill.setXmlParam("x", "50");
 seekFillCap.setXmlParam("x", "48");
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
 Int command = popup.popAtMouse();
 delete popup;
 if (command == 1) menuPlaylist.leftClick();
 if (command == 2) menuLibrary.leftClick();
 if (command == 3) menuEqualizer.leftClick();
 if (command == 4) menuVideo.leftClick();
 if (command == 5) menuVisualization.leftClick();
 if (command == 21) menuShuffle.leftClick();
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
scrollTimer.onTimer() { scrollTick(); }
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
 if (mainLayout.getWidth() <= 112) return;
 if (titleText.getTextWidth() != scrollTitleWidth || detailText.getTextWidth() != scrollDetailWidth || titleViewport.getWidth() != scrollViewWidth) {
  resetScroll();
  return;
 }
 if (scrollRestMs > 0) {
  if (delta <= scrollRestMs) { scrollRestMs = scrollRestMs - delta; delta = 0; }
  else { delta = delta - scrollRestMs; scrollRestMs = 0; }
 }
 Int longestCycle = 0;
 if (scrollTitleWidth > scrollViewWidth) longestCycle = scrollTitleWidth + 40;
 if (scrollDetailWidth > scrollViewWidth && scrollDetailWidth + 40 > longestCycle) longestCycle = scrollDetailWidth + 40;
 if (longestCycle == 0) scrollPhase = 0;
 else scrollPhase = scrollPhase + delta * 0.015;
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
 Int cycle = textWidth + 40;
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
