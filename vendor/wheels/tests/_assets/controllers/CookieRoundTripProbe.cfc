/**
 * HTTP fixture for TestClientSetCookieSpec: sets a cookie whose value needs URL
 * encoding, and echoes the value it receives back, so a spec can show the
 * TestClient cookie jar returns cookies as the server set them. Mounted under
 * /_cookieroundtrip in tests/routes.cfm.
 */
component extends="Controller" {

	function setValue() {
		cookie["_wheels_roundtrip_probe"] = "a+b/c=d e";
		renderText("set");
	}

	// Echoes the X-CSRF-Token header the request carried (TestClientCsrfSpec), so a
	// spec can see what TestClient sent. Not forgery-protected.
	function echoCsrfHeader() {
		var headers = GetHttpRequestData().headers;
		renderText("header=[" & (StructKeyExists(headers, "X-CSRF-Token") ? headers["X-CSRF-Token"] : "") & "]");
	}

	function readValue() {
		renderText("value=[" & (StructKeyExists(cookie, "_wheels_roundtrip_probe") ? cookie["_wheels_roundtrip_probe"] : "") & "]");
	}

}
