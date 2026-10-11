#include "std.mi"
// Skin-local font resources and ordinary Wasabi text attributes only.
Global Group fontRoot;
Global Timer fontTimer;
Global Int appliedFont;
Function updateFont();
Function applyFont(Group parentGroup, Int choice);

System.onScriptLoaded() {
 fontRoot = getScriptGroup();
 appliedFont = -1;
 fontTimer = new Timer;
 fontTimer.setDelay(250);
 fontTimer.start();
 updateFont();
}
System.onScriptUnloading() { fontTimer.stop(); delete fontTimer; }
fontRoot.onSetVisible(Boolean visible) {
 if (visible) { appliedFont = -1; updateFont(); }
}
fontTimer.onTimer() { updateFont(); }
updateFont() {
 Int choice = getPrivateInt("iTunes MiniPlayer", "display.font", 0);
 if (choice != 1) choice = 0;
 if (choice == appliedFont) return;
 applyFont(fontRoot, choice);
 appliedFont = choice;
}
applyFont(Group parentGroup, Int choice) {
 // A work list avoids recursive calls through MAKI's shared local variables.
 List groups = new List;
 groups.addItem(parentGroup);
 for (Int groupIndex = 0; groupIndex < groups.getNumItems(); groupIndex++) {
  Group current = groups.enumItem(groupIndex);
  for (Int index = 0; index < current.getNumObjects(); index++) {
  GuiObject item = current.enumObject(index);
  String className = item.getClassName();
  if (className == "Text") {
   String font = "Lucida Grande";
   String alternate = "Tahoma";
   if (choice == 1) {
    font = "mini.font.dejavu.regular";
    if (stringToInteger(item.getXmlParam("bold")) == 1) font = "mini.font.dejavu.bold";
    alternate = font;
   }
   item.setXmlParam("font", font);
   item.setXmlParam("altfont", alternate);
  }
  // Stay within the skin's own text. Embedded plugin clients choose their fonts.
  if (className == "Group" || className == "Layout") {
   groups.addItem(item);
  }
  }
 }
 delete groups;
}
