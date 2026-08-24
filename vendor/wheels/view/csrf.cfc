component {
	/**
	 * Include this in your layouts' `head` sections to include meta tags containing the authenticity token for use by JavaScript AJAX requests needing to `POST` data to your application.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function csrfMetaTags(any encode) {
		$args(name = "csrfMetaTags", args = arguments);
		local.encode = $coerceEncode(arguments.encode, true);
		local.metaTags = $tag(
			name = "meta",
			attributes = {name = "csrf-param", content = "authenticityToken"},
			encode = local.encode
		);
		local.metaTags &= $tag(
			name = "meta",
			attributes = {name = "csrf-token", content = $generateAuthenticityToken()},
			encode = local.encode
		);
		return local.metaTags;
	}

	/**
	 * Returns a hidden form field containing a new authenticity token.
	 *
	 * [section: View Helpers]
	 * [category: General Form Functions]
	 */
	public string function authenticityTokenField() {
		// Store a new authenticity token.
		local.authenticityToken = $generateAuthenticityToken();

		// Create hidden field containing the authenticity token.
		local.rv = hiddenFieldTag(name = "authenticityToken", value = local.authenticityToken);

		// Delete the id="authenticityToken" part of the string.
		// There could be multiple forms on a page and duplicate "id" attributes are not allowed in HTML.
		local.rv = Replace(local.rv, ' id="authenticityToken" ', " ");

		return local.rv;
	}
}
