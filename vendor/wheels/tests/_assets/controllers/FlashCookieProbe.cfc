/**
 * HTTP fixture for FlashCookieSameRequestSpec: with cookie flash storage, writes a
 * flash message and reads it back in the same request. Mounted under /_flashcookie
 * in tests/routes.cfm.
 */
component extends="Controller" {

	function insertAndRead() {
		setFlashStorage("cookie");
		flashInsert(notice = "saved");
		renderText("notice=[" & flash("notice") & "]");
	}

}
