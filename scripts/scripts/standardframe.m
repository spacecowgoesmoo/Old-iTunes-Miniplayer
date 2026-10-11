#include "std.mi"
// Standard Winamp XUI frame contract; no host-specific interfaces.
Global Group frameGroup, client;
Function installContent(String groupId);

System.onScriptLoaded() {
 frameGroup = getScriptGroup();
}
System.onSetXuiParam(String param, String value) {
 if (param == "content") installContent(value);
}
installContent(String groupId) {
 if (client != NULL) delete client;
 client = newGroup(groupId);
 if (client == NULL) return;
 // The standard frame XML states its client rectangle in script param.
 String geometry = getParam();
 client.setXmlParam("x", getToken(geometry, ",", 0));
 client.setXmlParam("y", getToken(geometry, ",", 1));
 client.setXmlParam("w", getToken(geometry, ",", 2));
 client.setXmlParam("h", getToken(geometry, ",", 3));
 client.setXmlParam("relatw", "1");
 client.setXmlParam("relath", "1");
 client.init(frameGroup);
}
