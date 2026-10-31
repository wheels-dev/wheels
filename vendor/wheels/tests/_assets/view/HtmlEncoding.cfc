/**
 * Encoder-agnostic helpers for view specs that check HTML encoding.
 *
 * Engines encode the same input differently. Lucee's ESAPI extension 2.x encodes almost every
 * non-alphanumeric character (`/` becomes `&#x2f;`, a space in an attribute `&#x20;`, `"` becomes
 * `&quot;`), while the 3.x extension shipped with Lucee 7.0.5 (built on the OWASP Java Encoder)
 * encodes only what the context needs (`"` becomes `&#34;`, `/` stays literal). Both are safe.
 *
 * `normalize()` lets a spec compare output against one literal expectation on either encoder:
 * every character reference is rewritten to a single canonical form. Characters that can change
 * the meaning of markup (`&`, `<`, `"`, `'`) always stay encoded, so a missing encoding of one of
 * them still fails the comparison. `>` is canonicalised to the literal character, because the
 * OWASP encoder leaves it literal inside attribute values, where it cannot end the tag; specs that
 * need `>` encoded in text assert that separately with `isSafeText()`.
 *
 * The safety helpers do not use the engine's encoder at all: they parse the generated markup.
 */
component {

	/**
	 * Rewrites every character reference to a canonical form: `&amp;`, `&lt;`, `&quot;` and
	 * `&#39;` for the markup-significant characters, the literal character for everything else.
	 */
	public string function normalize(required string html) {
		var rv = "";
		var pos = 1;
		var total = Len(arguments.html);
		while (pos <= total) {
			var found = REFind("&(##[xX][0-9a-fA-F]+|##[0-9]+|[a-zA-Z][a-zA-Z0-9]*);", arguments.html, pos, true);
			if (found.pos[1] == 0) {
				rv &= Mid(arguments.html, pos, total - pos + 1);
				break;
			}
			if (found.pos[1] > pos) {
				rv &= Mid(arguments.html, pos, found.pos[1] - pos);
			}
			var reference = Mid(arguments.html, found.pos[1], found.len[1]);
			var codePoint = $codePoint(Mid(arguments.html, found.pos[2], found.len[2]));
			rv &= codePoint == 0 ? reference : $canonical(codePoint);
			pos = found.pos[1] + found.len[1];
		}
		return rv;
	}

	/**
	 * Fully decodes the character references in a string (the value a browser would see).
	 */
	public string function decode(required string value) {
		var rv = "";
		var pos = 1;
		var total = Len(arguments.value);
		while (pos <= total) {
			var found = REFind("&(##[xX][0-9a-fA-F]+|##[0-9]+|[a-zA-Z][a-zA-Z0-9]*);", arguments.value, pos, true);
			if (found.pos[1] == 0) {
				rv &= Mid(arguments.value, pos, total - pos + 1);
				break;
			}
			if (found.pos[1] > pos) {
				rv &= Mid(arguments.value, pos, found.pos[1] - pos);
			}
			var codePoint = $codePoint(Mid(arguments.value, found.pos[2], found.len[2]));
			rv &= codePoint == 0 ? Mid(arguments.value, found.pos[1], found.len[1]) : Chr(codePoint);
			pos = found.pos[1] + found.len[1];
		}
		return rv;
	}

	/**
	 * Returns the double-quoted attributes of every tag in `html`, in order, as structs with the
	 * attribute `name` and its `raw` (still encoded) value. An attribute that broke out of its
	 * quotes shows up here as an attribute of its own.
	 */
	public array function attributes(required string html) {
		var rv = [];
		var pos = 1;
		while (true) {
			var found = REFind("\s([a-zA-Z_:][-a-zA-Z0-9_:.]*)=""([^""]*)""", arguments.html, pos, true);
			if (found.pos[1] == 0) {
				break;
			}
			ArrayAppend(rv, {
				name = LCase(Mid(arguments.html, found.pos[2], found.len[2])),
				raw = found.len[3] > 0 ? Mid(arguments.html, found.pos[3], found.len[3]) : ""
			});
			pos = found.pos[1] + found.len[1];
		}
		return rv;
	}

	/**
	 * Every opening `tag` in `html` (e.g. each `<input ...>`), in order. A literal `>` inside a
	 * quoted attribute value does not end the tag.
	 */
	public array function tags(required string html, required string tag) {
		return REMatchNoCase("<#arguments.tag#\b(?:[^>""]|""[^""]*"")*>", arguments.html);
	}

	/**
	 * Whether any tag in `html` carries an attribute called `name`.
	 */
	public boolean function hasAttribute(required string html, required string name) {
		for (var attribute in attributes(arguments.html)) {
			if (attribute.name == LCase(arguments.name)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * The raw (still encoded) value of the first attribute called `name`, or "" when there is none.
	 */
	public string function attributeValue(required string html, required string name) {
		for (var attribute in attributes(arguments.html)) {
			if (attribute.name == LCase(arguments.name)) {
				return attribute.raw;
			}
		}
		return "";
	}

	/**
	 * The raw text between the first opening `tag` and the next `<`, or "" when the tag is absent.
	 * Encoded text never contains a literal `<`, so this is the whole encoded text node. A literal
	 * `>` inside a quoted attribute value does not end the tag.
	 */
	public string function innerText(required string html, required string tag) {
		var found = REFindNoCase("<#arguments.tag#\b(?:[^>""]|""[^""]*"")*>([^<]*)", arguments.html, 1, true);
		if (found.pos[1] == 0 || found.len[2] == 0) {
			return "";
		}
		return Mid(arguments.html, found.pos[2], found.len[2]);
	}

	/**
	 * Whether a raw attribute value is safe inside double quotes: no literal `"`, `'` or `<`.
	 * A literal `>` is allowed, as it cannot end a quoted attribute value.
	 */
	public boolean function isSafeAttributeValue(required string raw) {
		return !Find("""", arguments.raw) && !Find("'", arguments.raw) && !Find("<", arguments.raw);
	}

	/**
	 * Whether raw text content carries no literal `<`, `>`, `"` or `'`.
	 */
	public boolean function isSafeText(required string raw) {
		return !Find("<", arguments.raw) && !Find(">", arguments.raw) && !Find("""", arguments.raw) && !Find("'", arguments.raw);
	}

	/**
	 * Checks that `input`, rendered into the `name` attribute of `html`, stayed one attribute value:
	 * no attribute the input tried to inject (`onclick=` in the input) appears on any tag, the value
	 * carries no literal `"`, `'` or `<`, and it decodes back to `input`. Returns "" when all hold,
	 * otherwise a description of the first problem.
	 */
	public string function attributeProblem(required string html, required string name, required string input) {
		for (var injected in REMatch("[a-zA-Z][-a-zA-Z0-9]*=", arguments.input)) {
			var injectedName = Left(injected, Len(injected) - 1);
			if (hasAttribute(arguments.html, injectedName)) {
				return "the input added a [#injectedName#] attribute: #arguments.html#";
			}
		}
		if (!hasAttribute(arguments.html, arguments.name)) {
			return "no [#arguments.name#] attribute in: #arguments.html#";
		}
		var raw = attributeValue(arguments.html, arguments.name);
		if (!isSafeAttributeValue(raw)) {
			return "[#arguments.name#] value has a literal quote or <: #raw#";
		}
		if (Compare(decode(raw), arguments.input) != 0) {
			return "[#arguments.name#] value decodes to [#decode(raw)#], not the input [#arguments.input#]";
		}
		return "";
	}

	/**
	 * Checks that the raw text node `raw` encodes `input` safely: no literal `<`, `>`, `"` or `'`,
	 * and it decodes back to `input`. Returns "" when both hold, otherwise a description.
	 */
	public string function textProblem(required string raw, required string input) {
		if (!isSafeText(arguments.raw)) {
			return "text has a literal <, >, quote or apostrophe: #arguments.raw#";
		}
		if (Compare(decode(arguments.raw), arguments.input) != 0) {
			return "text decodes to [#decode(arguments.raw)#], not the input [#arguments.input#]";
		}
		return "";
	}

	/**
	 * The code point of a character reference body (`#x2f`, `#47`, `quot`), or 0 when the named
	 * reference is not one this helper knows.
	 */
	public numeric function $codePoint(required string body) {
		if (Left(arguments.body, 2) == "##x" || Left(arguments.body, 2) == "##X") {
			return InputBaseN(Mid(arguments.body, 3, Len(arguments.body) - 2), 16);
		}
		if (Left(arguments.body, 1) == "##") {
			return Val(Mid(arguments.body, 2, Len(arguments.body) - 1));
		}
		switch (LCase(arguments.body)) {
			case "quot":
				return 34;
			case "apos":
				return 39;
			case "amp":
				return 38;
			case "lt":
				return 60;
			case "gt":
				return 62;
			case "nbsp":
				return 160;
		}
		return 0;
	}

	/**
	 * The canonical form of one decoded character.
	 */
	public string function $canonical(required numeric codePoint) {
		switch (arguments.codePoint) {
			case 38:
				return "&amp;";
			case 60:
				return "&lt;";
			case 34:
				return "&quot;";
			case 39:
				return "&##39;";
		}
		return Chr(arguments.codePoint);
	}

}
