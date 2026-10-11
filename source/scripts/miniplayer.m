#include "std.mi"
Global Group root;
Global Layout mainLayout;
Global Button playPause, libraryButton;
Global Button menuPlaylist, menuLibrary, menuEqualizer, menuVideo, menuVisualization;
Global GuiObject muteButton, dragArea;
Global Group lcdGroup;
Global GuiObject seekTrack, seeker;
Global Int adjustingSize;
Global Text titleText, detailText, elapsedText, remainingText;
Global Layer seekFill, seekFillCap;
Global Timer clockTimer, scrollTimer;
Global Text titleRepeat, detailRepeat;
Global Group titleViewport, detailViewport;
Global Double scrollPhase;
Global Int scrollPauseTicks, scrollTitleWidth, scrollDetailWidth, scrollViewWidth;
Global Int savedVolume;
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
 playPause = root.findObject("playpause");
 muteButton = root.findObject("mute");
 titleText = root.findObject("track.title");
 detailText = root.findObject("track.detail");
 elapsedText = root.findObject("time.elapsed");
 remainingText = root.findObject("time.remaining");
 seekFill = root.findObject("seek.fill");
 seekFillCap = root.findObject("seek.fill.cap");
 libraryButton = root.findObject("library");
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
 scrollPhase = 0; scrollPauseTicks = 40;
 scrollTimer = new Timer;
 scrollTimer.setDelay(50);
 scrollTimer.start();
 adjustingSize = 0;
 savedVolume = 180;
 clockTimer = new Timer;
 clockTimer.setDelay(250);
 clockTimer.start();
 updateDisplay(mainLayout.getWidth());
 updateTrack(); updateTime();
}
System.onScriptUnloading() { clockTimer.stop(); delete clockTimer; scrollTimer.stop(); delete scrollTimer; }
System.onTitleChange(String newTitle) { updateTrack(); updateTime(); }
System.onPlay() { updateTrack(); updateTime(); }
System.onStop() { updateTime(); }
System.onPause() { updateTime(); }
System.onResume() { updateTime(); }
System.onSeek(int newpos) { updateTime(); }
clockTimer.onTimer() { updateTime(); }

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
  Int available = mainLayout.getWidth() - 122;
  if (available >= 128) available = available - 100;
  else available = available - 42;
  if (available < 0) available = 0;
  Double fraction = position;
  fraction = fraction / length;
  Int width = fraction * (available + 4) - 2;
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
 mainLayout.resize(mainLayout.getLeft(), mainLayout.getTop(), width, 58);
 updateDisplay(width);
}
mainLayout.onResize(int x, int y, int w, int h) {
 if (adjustingSize) return;
 // Native resizing keeps mouse capture after the display snaps out of view.
 if (w > 112 && w < 198) {
  adjustingSize = 1;
  mainLayout.resize(x, y, 112, 58);
  adjustingSize = 0;
  w = 112;
 }
 updateDisplay(w);
}
updateDisplay(Int width) {
 if (width <= 112) { lcdGroup.hide(); return; }
 lcdGroup.show();
 Int lcdWidth = width - 122;
 if (lcdWidth < 128) {
  elapsedText.hide(); remainingText.hide();
  titleViewport.setXmlParam("x", "5"); titleViewport.setXmlParam("w", "-10");
  detailViewport.setXmlParam("x", "5"); detailViewport.setXmlParam("w", "-10");
  seeker.setXmlParam("x", "16"); seeker.setXmlParam("w", "-32");
  seekTrack.setXmlParam("x", "19"); seekTrack.setXmlParam("w", "-38");
  seekFill.setXmlParam("x", "21");
  seekFillCap.setXmlParam("x", "19");
 } else {
  elapsedText.show(); remainingText.show();
  titleViewport.setXmlParam("x", "14"); titleViewport.setXmlParam("w", "-28");
  detailViewport.setXmlParam("x", "14"); detailViewport.setXmlParam("w", "-28");
  seeker.setXmlParam("x", "45"); seeker.setXmlParam("w", "-90");
  seekTrack.setXmlParam("x", "48"); seekTrack.setXmlParam("w", "-96");
  seekFill.setXmlParam("x", "50");
  seekFillCap.setXmlParam("x", "48");
 }
 resetScroll();
 updateTime();
}
showMenu() {
 PopupMenu popup = new PopupMenu;
 popup.addCommand("Playlist Editor", 1, isNamedWindowVisible("guid:pl"), 0);
 popup.addCommand("Media Library", 2, isNamedWindowVisible("guid:ml"), 0);
 popup.addCommand("Equalizer", 3, isNamedWindowVisible("guid:eq"), 0);
 popup.addCommand("Video", 4, isNamedWindowVisible("guid:vid"), 0);
 popup.addCommand("Visualization", 5, isNamedWindowVisible("guid:avs"), 0);
 popup.addSeparator();
 popup.addCommand("Restore Standard Width", 41, 0, 0);
 Int command = popup.popAtMouse();
 delete popup;
 if (command == 1) menuPlaylist.leftClick();
 if (command == 2) menuLibrary.leftClick();
 if (command == 3) menuEqualizer.leftClick();
 if (command == 4) menuVideo.leftClick();
 if (command == 5) menuVisualization.leftClick();
 if (command == 41) setDisplayWidth(312);
}

// Reconstructed synchronized marquee: 15 px/s, one pass per row, then wait.
// Exact historical Apple timing is not documented; use a two-second rest.
scrollTimer.onTimer() { scrollTick(); }
resetScroll() {
 scrollPhase = 0;
 scrollPauseTicks = 40;
 scrollTitleWidth = titleText.getTextWidth();
 scrollDetailWidth = detailText.getTextWidth();
 scrollViewWidth = titleViewport.getWidth();
 renderScrollLine(titleText, titleRepeat, titleViewport, 0);
 renderScrollLine(detailText, detailRepeat, detailViewport, 0);
}
scrollTick() {
 if (mainLayout.getWidth() <= 112) return;
 if (titleText.getTextWidth() != scrollTitleWidth || detailText.getTextWidth() != scrollDetailWidth || titleViewport.getWidth() != scrollViewWidth) {
  resetScroll();
  return;
 }
 renderScrollLine(titleText, titleRepeat, titleViewport, scrollPhase);
 renderScrollLine(detailText, detailRepeat, detailViewport, scrollPhase);
 if (scrollPauseTicks > 0) { scrollPauseTicks = scrollPauseTicks - 1; return; }
 Int longestCycle = 0;
 if (scrollTitleWidth > scrollViewWidth) longestCycle = scrollTitleWidth + 40;
 if (scrollDetailWidth > scrollViewWidth && scrollDetailWidth + 40 > longestCycle) longestCycle = scrollDetailWidth + 40;
 if (longestCycle == 0) { scrollPhase = 0; return; }
 scrollPhase = scrollPhase + 0.75;
 if (scrollPhase >= longestCycle) {
  scrollPhase = 0;
  scrollPauseTicks = 40;
  renderScrollLine(titleText, titleRepeat, titleViewport, 0);
  renderScrollLine(detailText, detailRepeat, detailViewport, 0);
 }
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
