component {

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
	 * `<div title="#hAttr(user.bio)#">`.
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
