/**
 * wheels.Global include: strings
 * Inflection, truncation, and time-in-words helpers.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	// ======================================================================
	// TEXT FUNCTIONS
	// ======================================================================

	/**
	 * Internal function.
	 */
	public string function $singularizeOrPluralize(
		required string text,
		required string which,
		numeric count = -1,
		boolean returnCount = true
	) {
		// by default we pluralize/singularize the entire string
		local.text = arguments.text;

		// keep track of the success of any rule matches
		local.ruleMatched = false;

		// when count is 1 we don't need to pluralize at all so just set the return value to the input string
		local.rv = local.text;

		if (arguments.count != 1) {
			if (ReFind("[A-Z]", local.text)) {
				// only pluralize/singularize the last part of a camelCased variable (e.g. in "websiteStatusUpdate" we only change the "update" part)
				// also set a variable with the unchanged part of the string (to be prepended before returning final result)
				local.upperCasePos = ReFind("[A-Z]", Reverse(local.text));
				local.prepend = Mid(local.text, 1, Len(local.text) - local.upperCasePos);
				local.text = Reverse(Mid(Reverse(local.text), 1, local.upperCasePos));
			}

			// Get global settings for uncountable and irregular words.
			// For the irregular ones we need to convert them from a struct to a list.
			local.uncountables = $listClean($get("uncountables"));
			local.irregulars = "";
			local.words = $get("irregulars");
			for (local.word in local.words) {
				local.irregulars = ListAppend(local.irregulars, LCase(local.word));
				local.irregulars = ListAppend(local.irregulars, local.words[local.word]);
			}

			if (ListFindNoCase(local.uncountables, local.text)) {
				local.rv = local.text;
				local.ruleMatched = true;
			} else if (ListFindNoCase(local.irregulars, local.text)) {
				local.pos = ListFindNoCase(local.irregulars, local.text);
				if (arguments.which == "singularize" && local.pos % 2 == 0) {
					local.rv = ListGetAt(local.irregulars, local.pos - 1);
				} else if (arguments.which == "pluralize" && local.pos % 2 != 0) {
					local.rv = ListGetAt(local.irregulars, local.pos + 1);
				} else {
					local.rv = local.text;
				}
				local.ruleMatched = true;
			} else {
				if (arguments.which == "pluralize") {
					local.ruleList = "(quiz)$,\1zes,^(ox)$,\1en,([m|l])ouse$,\1ice,(matr|vert|ind)ix|ex$,\1ices,(x|ch|ss|sh)$,\1es,([^aeiouy]|qu)y$,\1ies,(hive)$,\1s,(?:([^f])fe|([lr])f)$,\1\2ves,sis$,ses,([ti])um$,\1a,(buffal|tomat|potat|volcan|her)o$,\1oes,(bu)s$,\1ses,(alias|status)$,\1es,(octop|vir)us$,\1i,(ax|test)is$,\1es,s$,s,$,s";
				} else if (arguments.which == "singularize") {
					local.ruleList = "(quiz)zes$,\1,(matr)ices$,\1ix,(vert|ind)ices$,\1ex,^(ox)en,\1,(alias|status)es$,\1,([octop|vir])i$,\1us,(cris|ax|test)es$,\1is,(shoe)s$,\1,(o)es$,\1,(bus)es$,\1,([m|l])ice$,\1ouse,(x|ch|ss|sh)es$,\1,(m)ovies$,\1ovie,(s)eries$,\1eries,([^aeiouy]|qu)ies$,\1y,([lr])ves$,\1f,(tive)s$,\1,(hive)s$,\1,([^f])ves$,\1fe,(^analy)ses$,\1sis,((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$,\1\2sis,([ti])a$,\1um,(n)ews$,\1ews,(.*)?ss$,\1ss,s$,#Chr(7)#";
				}
				local.rules = ArrayNew(2);
				local.count = 1;
				local.iEnd = ListLen(local.ruleList);
				for (local.i = 1; local.i <= local.iEnd; local.i = local.i + 2) {
					local.rules[local.count][1] = ListGetAt(local.ruleList, local.i);
					local.rules[local.count][2] = ListGetAt(local.ruleList, local.i + 1);
					local.count = local.count + 1;
				}
				local.iEnd = ArrayLen(local.rules);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					if (ReFindNoCase(local.rules[local.i][1], local.text)) {
						local.rv = ReReplaceNoCase(local.text, local.rules[local.i][1], local.rules[local.i][2]);
						local.ruleMatched = true;
						break;
					}
				}
				local.rv = Replace(local.rv, Chr(7), "", "all");
			}

			// this was a camelCased string and we need to prepend the unchanged part to the result
			if (StructKeyExists(local, "prepend") && local.ruleMatched) {
				local.rv = local.prepend & local.rv;
			}
		}

		// return the count number in the string (e.g. "5 sites" instead of just "sites")
		if (arguments.returnCount && arguments.count != -1) {
			local.rv = LsNumberFormat(arguments.count) & " " & local.rv;
		}
		return local.rv;
	}


	/**
	 * Capitalizes the first character of the supplied string.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @text String to capitalize.
	 */
	public string function capitalize(required string text) {
		local.rv = arguments.text;
		if (Len(local.rv)) {
			local.rv = UCase(Left(local.rv, 1)) & Mid(local.rv, 2, Len(local.rv) - 1);
		}
		return local.rv;
	}


	/**
	 * Returns readable text by capitalizing and converting camel casing to multiple words.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @text Text to humanize.
	 * @except A list of strings (space separated) to replace within the output.
	 *
	 */
	public string function humanize(required string text, string except = "") {
		// add a space before every capitalized word
		local.rv = ReReplace(arguments.text, "([[:upper:]])", " \1", "all");

		// remove space after punctuation chars
		local.rv = ReReplace(local.rv, "([[:punct:]])([[:space:]])", "\1", "all");

		// fix abbreviations so they form a word again (example: aURLVariable)
		local.rv = ReReplace(local.rv, "([[:upper:]]) ([[:upper:]])(?:\s|\b)", "\1\2", "all");
		local.rv = ReReplace(local.rv, "([[:upper:]])([[:upper:]])([[:lower:]])", "\1\2 \3", "all");

		if (Len(arguments.except)) {
			local.exceptKeysArray = ListToArray(arguments.except, " ");
			local.iEnd = ArrayLen(local.exceptKeysArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = local.exceptKeysArray[local.i];
				local.rv = ReReplaceNoCase(local.rv, "#local.item#(?:\b)", "#local.item#", "all");
			}
		}

		// support multiple word input by stripping out all double spaces created
		local.rv = Replace(local.rv, "  ", " ", "all");

		// capitalize the first letter and trim final result (which removes the leading space that happens if the string starts with an upper case character)
		local.rv = Trim(capitalize(local.rv));
		return local.rv;
	}


	/**
	 * Returns the plural form of the passed in word. Can also pluralize a word based on a value passed to the `count` argument. Wheels stores a list of words that are the same in both singular and plural form (e.g. "equipment", "information") and words that don't follow the regular pluralization rules (e.g. "child" / "children", "foot" / "feet"). Use `get("uncountables")` / `set("uncountables", newList)` and `get("irregulars")` / `set("irregulars", newList)` to modify them to suit your needs.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @word The word to pluralize.
	 * @count Pluralization will occur when this value is not 1.
	 * @returnCount Will return count prepended to the pluralization when true and count is not -1.
	 */
	public string function pluralize(required string word, numeric count = "-1", boolean returnCount = "true") {
		return $singularizeOrPluralize(
			count = arguments.count,
			returnCount = arguments.returnCount,
			text = arguments.word,
			which = "pluralize"
		);
	}


	/**
	 * Returns the singular form of the passed in word.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @word The word to singularize.
	 */
	public string function singularize(required string word) {
		return $singularizeOrPluralize(text = arguments.word, which = "singularize");
	}


	/**
	 * Converts camelCase strings to lowercase strings with hyphens as word delimiters instead. Example: myVariable becomes my-variable.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @string The string to hyphenize.
	 */
	public string function hyphenize(required string string) {
		local.rv = ReReplace(arguments.string, "([A-Z][a-z])", "-\l\1", "all");
		local.rv = ReReplace(local.rv, "([a-z])([A-Z])", "\1-\l\2", "all");
		local.rv = ReReplace(local.rv, "^-", "", "one");
		local.rv = LCase(local.rv);
		return local.rv;
	}


	/**
	 * Capitalizes all words in the text to create a nicer looking title.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @word The text to turn into a title.
	 */
	public string function titleize(required string word) {
		local.rv = "";
		local.iEnd = ListLen(arguments.word, " ");
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.rv = ListAppend(local.rv, capitalize(ListGetAt(arguments.word, local.i, " ")), " ");
		}
		return local.rv;
	}


	/**
	 * Truncates text to the specified length and replaces the last characters with the specified truncate string (which defaults to "...").
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @text The text to truncate.
	 * @length Length to truncate the text to.
	 * @truncateString String to replace the last characters with.
	 */
	public string function truncate(required string text, numeric length, string truncateString) {
		$args(name = "truncate", args = arguments);
		if (Len(arguments.text) > arguments.length) {
			local.rv = Left(arguments.text, arguments.length - Len(arguments.truncateString)) & arguments.truncateString;
		} else {
			local.rv = arguments.text;
		}
		return local.rv;
	}


	/**
	 * Truncates text to the specified length of words and replaces the remaining characters with the specified truncate string (which defaults to "...").
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @text The text to truncate.
	 * @length Number of words to truncate the text to.
	 * @truncateString String to replace the last characters with.
	 */
	public string function wordTruncate(required string text, numeric length, string truncateString) {
		$args(name = "wordTruncate", args = arguments);
		local.words = ListToArray(arguments.text, " ", false);

		// When there are fewer (or same) words in the string than the number to be truncated we can just return it unchanged.
		if (ArrayLen(local.words) <= arguments.length) {
			return arguments.text;
		}

		local.rv = "";
		local.iEnd = arguments.length;
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.rv = ListAppend(local.rv, local.words[local.i], " ");
		}
		local.rv &= arguments.truncateString;
		return local.rv;
	}


	/**
	 * Extracts an excerpt from text that matches the first instance of a given phrase.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @text The text to extract an excerpt from.
	 * @phrase The phrase to extract.
	 * @radius Number of characters to extract surrounding the phrase.
	 * @excerptString String to replace first and / or last characters with.
	 */
	public string function excerpt(required string text, required string phrase, numeric radius, string excerptString) {
		$args(name = "excerpt", args = arguments);
		local.pos = FindNoCase(arguments.phrase, arguments.text, 1);

		// Return an empty value if the text wasn't found at all.
		if (!local.pos) {
			return "";
		}

		// Set start info based on whether the excerpt text found, including its radius, comes before the start of the string.
		if ((local.pos - arguments.radius) <= 1) {
			local.startPos = 1;
			local.truncateStart = "";
		} else {
			local.startPos = local.pos - arguments.radius;
			local.truncateStart = arguments.excerptString;
		}

		// Set end info based on whether the excerpt text found, including its radius, comes after the end of the string.
		if ((local.pos + Len(arguments.phrase) + arguments.radius) > Len(arguments.text)) {
			local.endPos = Len(arguments.text);
			local.truncateEnd = "";
		} else {
			local.endPos = local.pos + arguments.radius;
			local.truncateEnd = arguments.excerptString;
		}

		local.len = (local.endPos + Len(arguments.phrase)) - local.startPos;
		local.mid = Mid(arguments.text, local.startPos, local.len);
		local.rv = local.truncateStart & local.mid & local.truncateEnd;
		return local.rv;
	}


	// ======================================================================
	// DATETIME FUNCTIONS
	// ======================================================================

	/**
	 * Internal function.
	 */
	public string function $timestamp(string timeStampMode = application.wheels.timeStampMode) {
		switch (arguments.timeStampMode) {
			case "utc":
				local.rv = DateConvert("local2Utc", Now());
				break;
			case "local":
				local.rv = Now();
				break;
			case "epoch":
				local.rv = Now().getTime();
				break;
			default:
				Throw(type = "Wheels.InvalidTimeStampMode", message = "Timestamp mode #arguments.timeStampMode# is invalid");
		}

		// Ensure adapterName is set (may not be if no model has been called yet)
		if (!StructKeyExists(application[$appKey()], "adapterName")) {
			local.dbType = $getDBType();
			$set(adapterName = "#local.dbType#Model");
		}

		// SQLite stores datetimes as TEXT. Format as a clean ISO-8601 string
		// (no surrounding quotes — those are SQL-literal syntax, not data) so
		// the value lands in the TEXT column verbatim and round-trips through
		// IsDate/DateFormat without quote-stripping.
		if ($get("adapterName") == "SQLiteModel") {
			if (IsDate(local.rv)) {
				local.rv = DateFormat(local.rv, "yyyy-mm-dd") & " " & TimeFormat(local.rv, "HH:mm:ss");
			}
		}

		return local.rv;
	}


	/**
	 * Pass in two dates to this method, and it will return a string describing the difference between them.
	 *
	 * [section: Global Helpers]
	 * [category: Date Functions]
	 *
	 * @fromTime Date to compare from.
	 * @toTime Date to compare to.
	 * @includeSeconds Whether or not to include the number of seconds in the returned string.
	 */
	public string function distanceOfTimeInWords(required date fromTime, required date toTime, boolean includeSeconds) {
		$args(name = "distanceOfTimeInWords", args = arguments);
		local.minuteDiff = DateDiff("n", arguments.fromTime, arguments.toTime);
		local.secondDiff = DateDiff("s", arguments.fromTime, arguments.toTime);
		local.hours = 0;
		local.days = 0;
		local.rv = "";
		if (local.minuteDiff <= 1) {
			if (local.secondDiff < 60) {
				local.rv = "less than a minute";
			} else {
				local.rv = "1 minute";
			}
			if (arguments.includeSeconds) {
				if (local.secondDiff < 5) {
					local.rv = "less than 5 seconds";
				} else if (local.secondDiff < 10) {
					local.rv = "less than 10 seconds";
				} else if (local.secondDiff < 20) {
					local.rv = "less than 20 seconds";
				} else if (local.secondDiff < 40) {
					local.rv = "half a minute";
				}
			}
		} else if (local.minuteDiff < 45) {
			local.rv = local.minuteDiff & " minutes";
		} else if (local.minuteDiff < 90) {
			local.rv = "about 1 hour";
		} else if (local.minuteDiff < 1440) {
			local.hours = Ceiling(local.minuteDiff / 60);
			local.rv = "about " & local.hours & " hours";
		} else if (local.minuteDiff < 2880) {
			local.rv = "1 day";
		} else if (local.minuteDiff < 43200) {
			local.days = Int(local.minuteDiff / 1440);
			local.rv = local.days & " days";
		} else if (local.minuteDiff < 86400) {
			local.rv = "about 1 month";
		} else if (local.minuteDiff < 525600) {
			local.months = Int(local.minuteDiff / 43200);
			local.rv = local.months & " months";
		} else if (local.minuteDiff < 657000) {
			local.rv = "about 1 year";
		} else if (local.minuteDiff < 919800) {
			local.rv = "over 1 year";
		} else if (local.minuteDiff < 1051200) {
			local.rv = "almost 2 years";
		} else if (local.minuteDiff >= 1051200) {
			local.years = Int(local.minuteDiff / 525600);
			local.rv = "over " & local.years & " years";
		}
		return local.rv;
	}


	/**
	 * Returns a string describing the approximate time difference between the date passed in and the current date.
	 *
	 * [section: Global Helpers]
	 * [category: Date Functions]
	 *
	 * @fromTime Date to compare from.
	 * @includeSeconds Whether or not to include the number of seconds in the returned string.
	 * @toTime Date to compare to.
	 */
	public any function timeAgoInWords(required date fromTime, boolean includeSeconds, date toTime = Now()) {
		$args(name = "timeAgoInWords", args = arguments);
		return distanceOfTimeInWords(argumentCollection = arguments);
	}


	/**
	 * Returns a string describing the approximate time difference between the current date and the date passed in.
	 *
	 * [section: Global Helpers]
	 * [category: Date Functions]
	 *
	 * @toTime Date to compare to.
	 * @includeSeconds Whether or not to include the number of seconds in the returned string.
	 * @fromTime Date to compare from.
	 */
	public string function timeUntilInWords(required date toTime, boolean includeSeconds, date fromTime = Now()) {
		$args(name = "timeUntilInWords", args = arguments);
		return distanceOfTimeInWords(argumentCollection = arguments);
	}
