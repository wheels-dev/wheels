/**
 * HTTP fixture for FlashCookieSameRequestSpec: with cookie flash storage, writes a
 * flash message and reads it back in the same request, and counts the flash an
 * incoming cookie carries. Mounted under /_flashcookie
 * in tests/routes.cfm.
 */
component extends="Controller" {

	function insertAndRead() {
		setFlashStorage("cookie");
		flashInsert(notice = "saved");
		renderText("notice=[" & flash("notice") & "]");
	}

	// Reads the cookie flash the request arrived with, without writing one.
	function readCount() {
		setFlashStorage("cookie");
		renderText("count=" & flashCount());
	}

}
