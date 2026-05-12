component {
	/**
	 * Removes all links from an HTML string, leaving just the link text.
	 *
	 * [section: View Helpers]
	 * [category: Sanitization Functions]
	 *
	 * @html The HTML to remove links from.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function stripLinks(required string html, boolean encode) {
		$args(name = "stripLinks", args = arguments);
		local.rv = ReReplaceNoCase(arguments.html, "<a.*?>(.*?)</a>", "\1", "all");
		if (arguments.encode && $get("encodeHtmlTags")) {
			local.rv = EncodeForHTML($canonicalize(local.rv));
		}
		return local.rv;
	}

	/**
	 * Removes all HTML tags from a string.
	 *
	 * [section: View Helpers]
	 * [category: Sanitization Functions]
	 *
	 * @html The HTML to remove tag markup from.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function stripTags(required string html, boolean encode) {
		$args(name = "stripTags", args = arguments);
		local.rv = ReReplaceNoCase(arguments.html, "<\ *[a-z].*?>", "", "all");
		local.rv = ReReplaceNoCase(local.rv, "<\ */\ *[a-z].*?>", "", "all");
		if (arguments.encode && $get("encodeHtmlTags")) {
			local.rv = EncodeForHTML($canonicalize(local.rv));
		}
		return local.rv;
	}

	/**
	 * Encodes a value for safe HTML output. Use in templates to prevent XSS:
	 * `#h(user.name)#` instead of `#user.name#`.
	 *
	 * [section: View Helpers]
	 * [category: Sanitization Functions]
	 *
	 * @value The value to encode for HTML output. Converted to string if not already.
	 */
	public string function h(required any value) {
		return EncodeForHTML(ToString(arguments.value));
	}

	/**
	 * Encodes a value for safe use inside an HTML attribute.
	 * Use when building attribute values manually:
     * &lt;div title="#hAttr(user.bio)#"&gt;.
	 *
	 * [section: View Helpers]
	 * [category: Sanitization Functions]
	 *
	 * @value The value to encode for HTML attribute context.
	 */
	public string function hAttr(required any value) {
		return EncodeForHTMLAttribute(ToString(arguments.value));
	}

}