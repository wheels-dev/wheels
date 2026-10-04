<cfscript>
/**
 * wheels.Global include: util
 * List/struct/args helpers, XML, obfuscation, MIME, UUID.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	// ======================================================================
	// PARAMS FUNCTIONS
	// ======================================================================

	/**
	 * Internal function.
	 */
	public any function $cleanInlist(required string where) {
		local.rv = arguments.where;
		local.regex = "IN\s?\(.*?,?\s?.*?\)";
		local.in = ReFind(local.regex, local.rv, 1, true);
		while (local.in.len[1]) {
			local.str = Mid(local.rv, local.in.pos[1], local.in.len[1]);
			local.rv = RemoveChars(local.rv, local.in.pos[1], local.in.len[1]);
			local.cleaned = $listClean(local.str);
			local.rv = Insert(local.cleaned, local.rv, local.in.pos[1] - 1);
			local.in = ReFind(local.regex, local.rv, local.in.pos[1] + Len(local.cleaned), true);
		}
		return local.rv;
	}


	/**
	 * Removes whitespace between list elements.
	 * Optional argument to return the list as an array.
	 */
	public any function $listClean(required string list, string delim = ",", string returnAs = "string") {
		local.rv = ListToArray(arguments.list, arguments.delim);
		local.iEnd = ArrayLen(local.rv);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.rv[local.i] = Trim(local.rv[local.i]);
		}
		if (arguments.returnAs != "array") {
			local.rv = ArrayToList(local.rv, arguments.delim);
		}
		return local.rv;
	}


	/**
	 * Converts a comma delimted list to a struct
	 */
	public struct function $listToStruct(required string list, string value = 1) {
		local.rv = {};
		local.cleanList = $listClean(list = arguments.list, returnAs = "array");
		for (local.key in local.cleanList) {
			local.rv[local.key] = arguments.value;
		}
		return local.rv;
	}


	/**
	 * Internal function. Wheels's canonical plural-or-singular argument alias
	 * helper. If `args.<second>` is set, copy it to `args.<first>` and delete
	 * the original — so the function body can read `args.<first>` uniformly
	 * regardless of which name the caller used. With `required=true`, throws
	 * `Wheels.IncorrectArguments` when neither name is provided.
	 *
	 * Canonical examples:
	 *   - `combine = "columnNames,columnName"` — migrator column helpers in
	 *     vendor/wheels/migrator/TableDefinition.cfc
	 *   - `combine = "properties,property"` — model validations in
	 *     vendor/wheels/model/validations.cfc
	 *   - `combine = "formats,format"` — controller provides() in
	 *     vendor/wheels/controller/provides.cfc
	 *   - `combine = "referenceNames,columnNames"` — t.references() per #2781
	 *
	 * When adding a new helper that takes a list-or-single argument, follow
	 * this pattern: declare the plural form on the signature (NOT required),
	 * then call $combineArguments(required=true) at the top of the body so the
	 * alias works AND the required-ness is enforced at runtime.
	 */
	public void function $combineArguments(
		required struct args,
		required string combine,
		required boolean required = false,
		string extendedInfo = ""
	) {
		local.first = ListGetAt(arguments.combine, 1);
		local.second = ListGetAt(arguments.combine, 2);
		if (StructKeyExists(arguments.args, local.second)) {
			arguments.args[local.first] = arguments.args[local.second];
			StructDelete(arguments.args, local.second);
		}
		if (arguments.required && $get("showErrorInformation")) {
			if (!StructKeyExists(arguments.args, local.first) || !Len(arguments.args[local.first])) {
				Throw(
					type = "Wheels.IncorrectArguments",
					message = "The `#local.second#` or `#local.first#` argument is required but was not passed in.",
					extendedInfo = "#arguments.extendedInfo#"
				);
			}
		}
	}



	/**
	 * Check to see if all keys in the list exist for the structure and have length.
	 */
	public boolean function $structKeysExist(required struct struct, string keys = "") {
		local.rv = true;
		local.keyArray = ListToArray(arguments.keys);
		local.iEnd = ArrayLen(local.keyArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.key = local.keyArray[local.i];
			if (
				!StructKeyExists(arguments.struct, local.key)
				|| (
					IsSimpleValue(arguments.struct[local.key])
					&& !Len(arguments.struct[local.key])
				)
			) {
				local.rv = false;
				break;
			}
		}
		return local.rv;
	}


	/**
	 * Creates a struct of the named arguments passed in to a function (i.e. the ones not explicitly defined in the arguments list).
	 *
	 * @defined List of already defined arguments that should not be added.
	 */
	public struct function $namedArguments(required string $defined) {
		local.rv = {};
		for (local.key in arguments) {
			if (!ListFindNoCase(arguments.$defined, local.key) && Left(local.key, 1) != "$") {
				local.rv[local.key] = arguments[local.key];
			}
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public struct function $dollarify(required struct input, required string on) {
		for (local.key in arguments.input) {
			if (ListFindNoCase(arguments.on, local.key)) {
				arguments.input["$" & local.key] = arguments.input[local.key];
				StructDelete(arguments.input, local.key);
			}
		}
		return arguments.input;
	}


	/**
	 * Internal function.
	 */
	public void function $args(
		required struct args,
		required string name,
		string reserved = "",
		string combine = "",
		string required = ""
	) {
		if (Len(arguments.combine)) {
			local.combineKeysArray = ListToArray(arguments.combine);
			local.iEnd = ArrayLen(local.combineKeysArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = local.combineKeysArray[local.i];
				local.first = ListGetAt(local.item, 1, "/");
				local.second = ListGetAt(local.item, 2, "/");
				local.required = false;
				if (ListLen(local.item, "/") > 2 || ListFindNoCase(local.first, arguments.required)) {
					local.required = true;
				}
				$combineArguments(args = arguments.args, combine = "#local.first#,#local.second#", required = local.required);
			}
		}
		if ($get("showErrorInformation")) {
			if (ListLen(arguments.reserved)) {
				local.iEnd = ListLen(arguments.reserved);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.item = ListGetAt(arguments.reserved, local.i);
					if (StructKeyExists(arguments.args, local.item)) {
						Throw(
							type = "Wheels.IncorrectArguments",
							message = "The `#local.item#` argument cannot be passed in since it will be set automatically by Wheels."
						);
					}
				}
			}
		}
		if (StructKeyExists(application.wheels.functions, arguments.name)) {
			$engineAdapter().structAppendDefaults(arguments.args, application.wheels.functions[arguments.name]);
		}

		// make sure that the arguments marked as required exist
		if (Len(arguments.required)) {
			local.requiredKeysArray = ListToArray(arguments.required);
			local.iEnd = ArrayLen(local.requiredKeysArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.arg = local.requiredKeysArray[local.i];
				if (!StructKeyExists(arguments.args, local.arg)) {
					Throw(
						type = "Wheels.IncorrectArguments",
						message = "The `#local.arg#` argument is required but not passed in."
					);
				}
			}
		}
	}


	// ======================================================================
	// MISC FUNCTIONS
	// ======================================================================

	/**
	 * The platform's native path separator, for path-containment normalisation (folds only
	 * real native separators, never a backslash seen in a POSIX filename). This Global mixin
	 * is reachable from mixed-in code (tags.cfm, Public.cfc); it delegates to
	 * wheels.PathGuard.$nativeSeparator() so the detection lives in exactly one place rather
	 * than being duplicated here. (PathGuard is a standalone component with no Global mixins,
	 * so the dependency only goes this direction.)
	 */
	public string function $nativePathSeparator() {
		return new wheels.PathGuard().$nativeSeparator();
	}

	/**
	 * Call CFML's canonicalize() function but set to blank string if the result is null (happens on Lucee 5).
	 */
	public string function $canonicalize(required string input) {
		try {
			local.rv = Canonicalize(arguments.input, false, false);
			if (IsNull(local.rv)) {
				local.rv = "";
			}
		} catch (any e) {
			// Lucee's Canonicalize() delegates to Java's URLDecoder, which throws
			// IllegalArgumentException for inputs containing malformed percent-encoded
			// sequences (e.g. %% or a lone % not followed by two hex digits).
			// Fall back to the raw input; it will still be HTML-encoded by the caller.
			local.rv = arguments.input;
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 * URL-encode a value for query strings with a normalized space form.
	 * Engines differ: Lucee emits "+" for a space (form-encoding style) while
	 * RustCFML emits "%20". A literal "+" in the input is %2B-encoded by every
	 * engine, so any remaining "%20" is a space — normalize to "+" so generated
	 * URLs are byte-identical across engines and match the spec contract.
	 */
	public string function $encodeUrlParam(required string value) {
		return Replace(EncodeForURL($canonicalize(arguments.value)), "%20", "+", "all");
	}


	/**
	 * Internal function.
	 * Normalize a timestamp value read back from a database into a CFML date,
	 * or return "" when the value is not a recognized timestamp shape.
	 *
	 * Most engines hand datetime columns back as a CFML date or a datetime
	 * string, but two shapes need bridging (#3649):
	 *
	 * - Oracle's JDBC driver returns TIMESTAMP columns as `oracle.sql.TIMESTAMP`,
	 *   which is NOT a `java.util.Date` and which Adobe CF's `IsDate()` answers
	 *   with the string "NO". Its `timestampValue()` method bridges to a
	 *   `java.sql.Timestamp`.
	 * - Some drivers append fractional seconds ("2026-09-22 20:24:54.205"),
	 *   which `IsDate()` also rejects; the whole-second prefix is enough for
	 *   every caller here.
	 * - Adobe + sqlite-jdbc returns raw epoch milliseconds, which the old
	 *   SQLite-only inline conversion in `JobWorker` special-cased.
	 *
	 * A `java.util.Date` is converted through `java.util.Calendar`, so the
	 * resulting CFML date is the instant in the JVM's timezone — the same
	 * reading `DateDiff()` against `Now()` expects.
	 */
	public any function $normalizeDbTimestamp(required any value) {
		if (IsDate(arguments.value)) {
			return arguments.value;
		}
		// Epoch milliseconds — a plain number, or a boxed java.lang.Number
		// (Adobe + sqlite-jdbc hands the column back as java.lang.Long). Both
		// are numeric on every engine, so this is the hot path for SQLite.
		if (IsNumeric(arguments.value)) {
			try {
				return $javaCalendarToDate($epochMillisCalendar(JavaCast("long", arguments.value)));
			} catch (any e) {
				// JVM-free engine (RustCFML) — plain epoch arithmetic instead.
				return DateAdd("s", Int(arguments.value / 1000), CreateDate(1970, 1, 1));
			}
		}
		// Datetime strings, including the fractional-second form
		// ("2026-09-22 20:24:54.205") that IsDate() rejects.
		if (IsSimpleValue(arguments.value)) {
			if (Len(arguments.value) >= 19) {
				try {
					local.parsed = ParseDateTime(Left(arguments.value, 19));
					if (IsDate(local.parsed)) {
						return local.parsed;
					}
				} catch (any e) {
					// Not a parseable datetime string.
				}
			}
			return "";
		}
		// Driver objects. Deliberately NOT gated on IsObject(): Lucee reports
		// java.util.Date and other boxed Java values as simple values, and the
		// java.sql.Timestamp that the Oracle bridge returns is one of those —
		// so IsObject() is false for the very objects this branch exists for.
		try {
			if (IsInstanceOf(arguments.value, "java.lang.Number")) {
				return $javaCalendarToDate($epochMillisCalendar(arguments.value.longValue()));
			}
		} catch (any e) {
			// Not a boxed number.
		}
		try {
			if (IsInstanceOf(arguments.value, "java.util.Date")) {
				return $javaDateToCfml(arguments.value);
			}
		} catch (any e) {
			// Not a java.util.Date — try the Oracle bridge below.
		}
		try {
			// oracle.sql.TIMESTAMP is not a java.util.Date, but bridges to one.
			local.bridged = arguments.value.timestampValue();
			if (IsInstanceOf(local.bridged, "java.util.Date")) {
				return $javaDateToCfml(local.bridged);
			}
		} catch (any e) {
			// Not an oracle.sql.TIMESTAMP either.
		}
		return "";
	}


	/**
	 * Internal function.
	 * A printable description of any value read back from a database, for
	 * diagnostics. Never casts a driver object to a string: BoxLang throws
	 * "Can't cast oracle.sql.TIMESTAMP to a string" on concatenation, which
	 * turned a failure message into the failure (#3714).
	 */
	public string function $describeDbValue(required any value) {
		if (IsSimpleValue(arguments.value)) {
			try {
				return "" & arguments.value;
			} catch (any e) {
				// Reported as simple but not castable; describe it by type below.
			}
		}
		if (IsStruct(arguments.value) && !IsObject(arguments.value)) {
			return "[struct]";
		}
		if (IsArray(arguments.value)) {
			return "[array]";
		}
		if (IsQuery(arguments.value)) {
			return "[query]";
		}
		try {
			local.meta = GetMetadata(arguments.value);
			if (IsStruct(local.meta) && StructKeyExists(local.meta, "fullname")) {
				return "[component " & local.meta.fullname & "]";
			}
		} catch (any e) {
			// Not a component.
		}
		try {
			return "[object " & arguments.value.getClass().getName() & "]";
		} catch (any e) {
			return "[unprintable value]";
		}
	}


	/**
	 * Internal function for `$normalizeDbTimestamp()`. Converts a
	 * `java.util.Date` into a CFML date through `java.util.Calendar`, so the
	 * result is the instant in the JVM's default timezone — the same reading
	 * `DateDiff()` against `Now()` expects.
	 */
	public date function $javaDateToCfml(required any javaDate) {
		local.cal = CreateObject("java", "java.util.Calendar").getInstance();
		local.cal.setTime(arguments.javaDate);
		return $javaCalendarToDate(local.cal);
	}


	/**
	 * Internal function for `$normalizeDbTimestamp()`. A Calendar for an epoch
	 * millisecond count, in the JVM's default timezone.
	 */
	public any function $epochMillisCalendar(required any millis) {
		local.cal = CreateObject("java", "java.util.Calendar").getInstance();
		if (IsInstanceOf(arguments.millis, "java.lang.Number")) {
			// Already a Java number (e.g. java.lang.Long) — no cast needed.
			local.cal.setTimeInMillis(arguments.millis.longValue());
		} else {
			local.cal.setTimeInMillis(JavaCast("long", arguments.millis));
		}
		return local.cal;
	}


	/**
	 * Internal function for `$normalizeDbTimestamp()`. Reads the calendar fields
	 * with the numeric `java.util.Calendar` constants: YEAR=1, MONTH=2 (zero
	 * based), DAY_OF_MONTH=5, HOUR_OF_DAY=11, MINUTE=12, SECOND=13.
	 */
	public date function $javaCalendarToDate(required any calendar) {
		return CreateDateTime(
			year = arguments.calendar.get(1),
			month = arguments.calendar.get(2) + 1,
			day = arguments.calendar.get(5),
			hour = arguments.calendar.get(11),
			minute = arguments.calendar.get(12),
			second = arguments.calendar.get(13)
		);
	}


	/**
	 * Internal function.
	 * HTML-escape text for the debug bar (complexity panel), the development
	 * error page, the docs viewer, and legacy test output.
	 *
	 * `HtmlEditFormat` is preferred where the engine provides it — it preserves
	 * "/", so file paths in the complexity panel stay readable (#3548). Adobe CF
	 * 2025 removed the BIF entirely — `Variable HTMLEDITFORMAT is undefined` —
	 * which 500s every surface that used it (#3645). Probe for it once per
	 * application and fall back to a local escaper with the same character set,
	 * so the debug bar reports problems instead of becoming one.
	 *
	 * The fallback is deliberately NOT `EncodeForHTML`: that encodes "/" as
	 * "&#x2f;" on some engines, which breaks the complexity panel's path
	 * assertions and the panel regression (#3548).
	 *
	 * Call sites must go through this helper rather than the BIF directly;
	 * `HtmlEditFormatGuardSpec` enforces that.
	 */
	public string function $encodeForDisplayText(required string value) {
		if (!StructKeyExists(application.wheels, "$displayTextEncoder")) {
			try {
				HtmlEditFormat("");
				application.wheels.$displayTextEncoder = "HtmlEditFormat";
			} catch (any e) {
				application.wheels.$displayTextEncoder = "local";
			}
		}
		if (application.wheels.$displayTextEncoder == "HtmlEditFormat") {
			return HtmlEditFormat(arguments.value);
		}
		// Ampersand first, then the markup characters: ReplaceList() re-scans
		// what it just inserted on Lucee, so escaping "<" before "&" turns the
		// generated "&lt;" into "&amp;lt;".
		local.rv = Replace(arguments.value, "&", "&amp;", "all");
		local.rv = Replace(local.rv, "<", "&lt;", "all");
		local.rv = Replace(local.rv, ">", "&gt;", "all");
		return Replace(local.rv, """", "&quot;", "all");
	}


	/**
	 * Internal function.
	 * Disambiguates a D1/D2/YYYY slash date: a component greater than 12 cannot
	 * be a month so the format is unambiguous; otherwise the engine adapter's
	 * locale preference decides (MM/DD/YYYY on Lucee / Adobe, DD/MM/YYYY on
	 * BoxLang). All slash-date parsing should funnel through this helper.
	 */
	public date function $parseSlashDate(required numeric d1, required numeric d2, required numeric year) {
		if (arguments.d1 > 12) {
			// the first component cannot be a month so it must be the day (DD/MM/YYYY)
			return CreateDate(arguments.year, arguments.d2, arguments.d1);
		} else if (arguments.d2 > 12) {
			// the second component cannot be a month so it must be the day (MM/DD/YYYY)
			return CreateDate(arguments.year, arguments.d1, arguments.d2);
		} else {
			return $engineAdapter().parseAmbiguousSlashDate(arguments.d1, arguments.d2, arguments.year);
		}
	}


	/**
	 * Internal function.
	 */
	public string function $convertToString(required any value, string type = "") {
		// Normalize inputs
		local.val = arguments.value;
		local.detectedType = arguments.type;

		// Coerce Oracle JDBC objects (TIMESTAMP, DATE) to CFML datetime values.
		if (IsObject(local.val)) {
			local.coerced = $engineAdapter().coerceOracleObject(local.val);
			if (!IsObject(local.coerced) || local.coerced.hashCode() != local.val.hashCode()) {
				local.val = local.coerced;
				if (IsDate(local.val)) {
					local.detectedType = "datetime";
				} else {
					local.detectedType = "string";
				}
			}
		}

		// If no explicit type passed, try to detect a sensible one
		if (!Len(local.detectedType)) {
			local.detectedType = $convertToStringDetectType(local.val);
		}

		// --- EARLY DATE/TIME PROMOTION ---
		// If the caller provided a non-datetime type (eg "string") but the value looks like a date/time,
		// promote it to datetime so the switch branch will canonicalize properly.
		local.detectedType = $convertToStringPromoteDatetime(local.val, local.detectedType);

		// Pre-process date strings with AM/PM that may be parsed differently per engine
		if (
			$engineAdapter().isBoxLang() && IsSimpleValue(arguments.value) && ReFindNoCase(
				"^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2} (AM|PM)$",
				arguments.value
			)
		) {
			// Manually parse the slash date to avoid engine-specific interpretation,
			// disambiguating day/month through $parseSlashDate()
			local.val = $convertToStringBoxLangSlashDatetime(arguments.value);
			local.detectedType = "datetime";
		}

		// --- SWITCH ON (possibly promoted) TYPE ---
		switch (local.detectedType) {
			case "array":
				return ArrayToList(local.val);
			case "struct":
				return $convertToStringStruct(local.val);
			case "binary":
				return ToString(local.val);
			case "float":
			case "integer":
				return $convertToStringNumber(local.val);
			case "boolean":
				return $convertToStringBoolean(local.val);
			case "datetime":
				return $convertToStringDatetime(local.val);
			default:
				// Default: return raw value as string (no conversion)
				return local.val;
		}
	}


	/**
	 * Internal function.
	 * Detects a sensible conversion type for a value when the caller did not
	 * pass an explicit type.
	 */
	public string function $convertToStringDetectType(required any val) {
		if (IsArray(arguments.val)) {
			return "array";
		} else if (IsStruct(arguments.val)) {
			return "struct";
		} else if (IsBinary(arguments.val)) {
			return "binary";
		} else if (IsNumeric(arguments.val)) {
			return "integer";
		} else if (IsDate(arguments.val)) {
			return "datetime";
		}
		return "string";
	}


	/**
	 * Internal function.
	 * Promotes a non-datetime simple value to "datetime" when it looks like a
	 * date/time, so the switch branch canonicalizes it instead of returning it raw.
	 */
	public string function $convertToStringPromoteDatetime(required any val, required string detectedType) {
		if (arguments.detectedType NEQ "datetime" AND IsSimpleValue(arguments.val) AND Len(Trim(arguments.val))) {
			local.s = Trim(arguments.val);

			// Match patterns loosely so they work for plain dates too
			local.patternAMPM = '^\d{1,2}/\d{1,2}/\d{4}(\s+\d{1,2}:\d{2}(\s*(AM|PM))?)?$';
			local.patternISO = '^\d{4}-\d{2}-\d{2}([ T]\d{2}:\d{2}(:\d{2})?)?$';
			local.patternSlash = '^\s*\d{1,2}/\d{1,2}/\d{4}\s*$';

			// Day name or other verbose formats are ignored to avoid false positives
			if (
				ReFindNoCase(local.patternAMPM, local.s) OR ReFindNoCase(local.patternISO, local.s) OR ReFindNoCase(
					local.patternSlash,
					local.s
				)
			) {
				return "datetime";
			}
		}
		return arguments.detectedType;
	}


	/**
	 * Internal function.
	 * Manually parses a BoxLang AM/PM slash date to avoid engine-specific
	 * interpretation, disambiguating day/month through $parseSlashDate().
	 */
	public date function $convertToStringBoxLangSlashDatetime(required string value) {
		local.parts = ListToArray(arguments.value, " ");
		local.datePart = local.parts[1];
		local.timePart = local.parts[2];
		local.amPm = local.parts[3];

		local.dateComponents = ListToArray(local.datePart, "/");
		local.timeComponents = ListToArray(local.timePart, ":");

		local.parsedDate = $parseSlashDate(
			d1 = Val(local.dateComponents[1]),
			d2 = Val(local.dateComponents[2]),
			year = Val(local.dateComponents[3])
		);
		local.hour = Val(local.timeComponents[1]);
		local.minute = Val(local.timeComponents[2]);

		if (local.amPm == "PM" && local.hour != 12) {
			local.hour += 12;
		} else if (local.amPm == "AM" && local.hour == 12) {
			local.hour = 0;
		}
		return CreateDateTime(
			Year(local.parsedDate),
			Month(local.parsedDate),
			Day(local.parsedDate),
			local.hour,
			local.minute,
			0
		);
	}


	/**
	 * Internal function.
	 * Serializes a struct to a sorted "key=value,key=value" list.
	 */
	public string function $convertToStringStruct(required any val) {
		local.kList = ListSort(StructKeyList(arguments.val), "textnocase", "asc");
		local.out = "";
		for (local.k in ListToArray(local.kList)) {
			local.out = ListAppend(local.out, local.k & "=" & arguments.val[local.k]);
		}
		return local.out;
	}


	/**
	 * Internal function.
	 * Serializes a numeric value (float/integer) to its string form.
	 */
	public string function $convertToStringNumber(required any val) {
		if (!Len(arguments.val)) {
			return "";
		}
		if (arguments.val == "true") {
			return "1";
		}
		return Val(arguments.val);
	}


	/**
	 * Internal function.
	 * Serializes a boolean value to "true"/"false" (or "" when empty).
	 */
	public string function $convertToStringBoolean(required any val) {
		if (Len(arguments.val)) {
			return (arguments.val IS true) ? "true" : "false";
		}
		return "";
	}


	/**
	 * Internal function.
	 * Canonicalizes a datetime value (date object or date-like string) to
	 * "yyyy-mm-dd HH:mm:ss".
	 */
	public string function $convertToStringDatetime(required any val) {
		// If it's already a date object, canonicalize
		if (IsDate(arguments.val)) {
			return DateFormat(arguments.val, "yyyy-mm-dd") & " " & TimeFormat(arguments.val, "HH:mm:ss");
		}

		// If it is a string that looks like a date, try parsing
		if (IsSimpleValue(arguments.val)) {
			local.s2 = Trim(arguments.val);
			// Try ParseDateTime (which handles many formats)
			try {
				local.dt = ParseDateTime(local.s2);
				if (IsDate(local.dt)) {
					return DateFormat(local.dt, "yyyy-mm-dd") & " " & TimeFormat(local.dt, "HH:mm:ss");
				}
			} catch (any e) {
				// fallback parsing attempts for common formats

				// 1) ISO YYYY-MM-DD[ hh[:mm[:ss]]]
				// Single-backslash escapes: in CFML "\\d" is a literal
				// backslash + d in the compiled regex, which never matches a
				// digit — the branch was dead. Mirrors the already-fixed
				// slash-format branch below (#2933 carry-forward, #2977).
				if (ReFind("(?i)^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$", local.s2)) {
					local.parts = ReReplace(local.s2, "^(\d{4})-(\d{2})-(\d{2}).*$", "\1-\2-\3", "all");
					local.timePart = ReReplace(local.s2, ".*[ T](\d{1,2}:\d{2}(?::\d{2})?).*$", "\1", "all");
					if (Len(local.timePart) AND local.timePart NEQ local.s2) {
						// has time
						local.dt = ParseDateTime(local.parts & " " & local.timePart);
						if (IsDate(local.dt)) {
							return DateFormat(local.dt, "yyyy-mm-dd") & " " & TimeFormat(local.dt, "HH:mm:ss");
						}
					} else {
						// date only
						local.dt = CreateDate(
							Val(ListGetAt(local.parts, 1, "-")),
							Val(ListGetAt(local.parts, 2, "-")),
							Val(ListGetAt(local.parts, 3, "-"))
						);
						return DateFormat(local.dt, "yyyy-mm-dd") & " 00:00:00";
					}
				}

				// 2) Slash format DD/MM/YYYY or MM/DD/YYYY — disambiguated by $parseSlashDate()
				if (ReFind("^\d{1,2}/\d{1,2}/\d{4}", local.s2)) {
					local.comps = ListToArray(local.s2, "/");
					local.dt = $parseSlashDate(
						d1 = Val(local.comps[1]),
						d2 = Val(local.comps[2]),
						year = Val(local.comps[3])
					);
					// if time exists in same string, try to parse it using ParseDateTime
					if (ReFind("\d{1,2}:\d{2}", local.s2)) {
						try {
							local.dt2 = ParseDateTime(local.s2);
							if (IsDate(local.dt2)) {
								return DateFormat(local.dt2, "yyyy-mm-dd") & " " & TimeFormat(local.dt2, "HH:mm:ss");
							}
						} catch (any e2) {
							// fallback to midnight
							return DateFormat(local.dt, "yyyy-mm-dd") & " 00:00:00";
						}
					}
					return DateFormat(local.dt, "yyyy-mm-dd") & " 00:00:00";
				}
			}
		}
		// If we reach here, parsing failed — return original string to allow comparison
		return arguments.val;
	}


	/**
	 * Internal function.
	 */
	public xml function $toXml(required any data) {
		// only instantiate the toXml object once per request
		if (!StructKeyExists(request.wheels, "toXml")) {
			request.wheels.toXml = $createObjectFromRoot(
				path = "#application.wheels.wheelsComponentPath#.vendor.toXml",
				fileName = "toXML",
				method = "init"
			);
		}

		return request.wheels.toXml.toXml(arguments.data);
	}


	/**
	 * Obfuscates a value. Typically used for hiding primary key values when passed along in the URL.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @param The value to obfuscate.
	 */
	public string function obfuscateParam(required any param) {
		local.rv = arguments.param;
		local.param = ArrayToList(ReMatch("[0-9]+", arguments.param), "");
		if (Len(local.param) && local.param > 0 && Left(local.param, 1) != 0) {
			local.iEnd = Len(local.param);
			local.a = (10^local.iEnd) + Reverse(local.param);
			local.b = 0;
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.b += Left(Right(local.param, local.i), 1);
			}
			if (IsValid("integer", local.a)) {
				local.rv = FormatBaseN(local.b + 154, 16) & FormatBaseN(BitXor(local.a, 461), 16);
			}
		}
		return local.rv;
	}


	/**
	 * Deobfuscates a value.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @param The value to deobfuscate.
	 */
	public string function deobfuscateParam(required string param) {
		if (Val(arguments.param) != arguments.param) {
			try {
				local.checksum = Left(arguments.param, 2);
				local.rv = Right(arguments.param, Len(arguments.param) - 2);
				local.z = BitXor(InputBaseN(local.rv, 16), 461);
				local.rv = "";
				local.iEnd = Len(local.z) - 1;
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.rv &= Left(Right(local.z, local.i), 1);
				}
				local.checkSumTest = 0;
				local.iEnd = Len(local.rv);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.checkSumTest += Left(Right(local.rv, local.i), 1);
				}
				local.c1 = ToString(FormatBaseN(local.checkSumTest + 154, 10));
				local.c2 = InputBaseN(local.checksum, 16);
				if (local.c1 != local.c2) {
					local.rv = arguments.param;
				}
			} catch (any e) {
				local.rv = arguments.param;
			}
		} else {
			local.rv = arguments.param;
		}
		return local.rv;
	}


	/**
	 * Returns an associated MIME type based on a file extension.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @extension The extension to get the MIME type for.
	 * @fallback The fallback MIME type to return.
	 */
	public string function mimeTypes(required string extension, string fallback = "application/octet-stream") {
		local.rv = arguments.fallback;
		if (StructKeyExists(application.wheels.mimetypes, arguments.extension)) {
			local.rv = application.wheels.mimetypes[arguments.extension];
		}
		return local.rv;
	}


	/**
	 * Adds a new MIME type to your Wheels application for use with responding to multiple formats.
	 *
	 * [section: Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @extension File extension to add.
	 * @mimeType Matching MIME type to associate with the file extension.
	 */
	public void function addFormat(required string extension, required string mimeType) {
		local.appKey = $appKey();
		application[local.appKey].formats[arguments.extension] = arguments.mimeType;
	}


	/**
	 * Internal function.
	 */
	public string function $appKey() {
		local.rv = "wheels";
		if (StructKeyExists(application, "$wheels")) {
			local.rv = "$wheels";
		}
		return local.rv;
	}

	/**
	 * Datasource the migrator should use for this request.
	 * Prefer a request-scoped override (TenantMigrator) so tenant runs do
	 * not mutate application.wheels.dataSourceName, which concurrent
	 * requests read without the tenant lock.
	 */
	public string function $migratorDataSource() {
		if (IsDefined("request.wheels.migratorDataSource") && Len(ToString(request.wheels.migratorDataSource))) {
			return ToString(request.wheels.migratorDataSource);
		}
		if (IsDefined("request.wheels.tenant.dataSource") && Len(ToString(request.wheels.tenant.dataSource))) {
			return ToString(request.wheels.tenant.dataSource);
		}
		return application[$appKey()].dataSourceName;
	}

	/**
	 * Username/password the migrator should use for $dbinfo probes.
	 * TenantMigrator may set request-scoped overrides so a tenant DS
	 * with its own credentials does not silently reuse the app DS user.
	 */
	public struct function $migratorDataSourceCredentials() {
		var creds = {username = "", password = ""};
		if (IsDefined("request.wheels.migratorDataSourceUserName")) {
			creds.username = ToString(request.wheels.migratorDataSourceUserName);
			if (IsDefined("request.wheels.migratorDataSourcePassword")) {
				creds.password = ToString(request.wheels.migratorDataSourcePassword);
			}
			return creds;
		}
		var appKey = $appKey();
		creds.username = application[appKey].dataSourceUserName;
		creds.password = application[appKey].dataSourcePassword;
		return creds;
	}


	// Integer-literal helpers shared by models (nested-property keys, #4128) and database
	// adapters (SQLite bind width, #4089): compared as digit strings, never through a double.

	/**
	 * Internal function. "<sign><digits>" with no leading zeros for an integer literal, or ""
	 * when the value is not one.
	 */
	public string function $canonicalIntegerString(required string value) {
		local.value = Trim(arguments.value);
		if (!ReFind("^[+-]?[0-9]+$", local.value)) {
			return "";
		}
		local.sign = Left(local.value, 1) == "-" ? "-" : "";
		local.digits = ReReplace(local.value, "^[+-]?0*", "");
		if (!Len(local.digits)) {
			return "0";
		}
		return local.sign & local.digits;
	}

	/**
	 * Internal function. -1, 0 or 1 as canonical integer string a is below, equal to or above b,
	 * compared by sign, then length, then digits.
	 */
	public numeric function $compareIntegerStrings(required string a, required string b) {
		local.aNegative = Left(arguments.a, 1) == "-";
		local.bNegative = Left(arguments.b, 1) == "-";
		if (local.aNegative != local.bNegative) {
			return local.aNegative ? -1 : 1;
		}
		local.aDigits = ReReplace(arguments.a, "^-", "");
		local.bDigits = ReReplace(arguments.b, "^-", "");
		if (Len(local.aDigits) != Len(local.bDigits)) {
			local.rv = Len(local.aDigits) > Len(local.bDigits) ? 1 : -1;
		} else {
			local.rv = Sgn(Compare(local.aDigits, local.bDigits));
		}
		return local.aNegative ? -local.rv : local.rv;
	}

	/**
	 * Generates a 36-character UUID compatible with SQL Server's uniqueidentifier.
	 *
	 * [section: Global Helpers]
	 * [category: UUID Functions]
	 *
	 * @return A valid 36-character UUID string (e.g., 123e4567-e89b-12d3-a456-426614174000)
	 */
	public string function generateUUID() {
		// Java's version 4 UUID where the JVM provides one. The result is checked, not trusted:
		// RustCFML answers CreateObject("java", "java.util.UUID") with a zero-filled value rather
		// than an error. CreateUUID() is not used: it returns a 35-character 8-4-4-16 string.
		local.candidate = "";
		try {
			local.candidate = LCase(CreateObject("java", "java.util.UUID").randomUUID().toString());
		} catch (any e) {
			// no JVM UUID; use the fallback below
		}
		if (ReFind("^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$", local.candidate)) {
			return local.candidate;
		}
		return $randomUuidV4();
	}

	/**
	 * Internal function. A version 4 UUID (8-4-4-4-12, lowercase) built from 16 bytes of
	 * GenerateSecretKey(), a cryptographically strong source on every supported engine, unlike
	 * RandRange()/Rand(), whose generator is seedable (RustCFML ignores their algorithm
	 * argument). Throws when no strong source is available rather than returning a weak value.
	 */
	public string function $randomUuidV4() {
		try {
			local.hex = LCase(BinaryEncode(BinaryDecode(GenerateSecretKey("AES", 128), "base64"), "hex"));
		} catch (any e) {
			Throw(
				type = "Wheels.NoSecureRandom",
				message = "generateUUID() needs a cryptographically strong random source, and none is available on this engine.",
				extendedInfo = e.message
			);
		}
		if (Len(local.hex) != 32) {
			Throw(type = "Wheels.NoSecureRandom", message = "generateUUID() could not read 16 random bytes on this engine.");
		}
		local.variant = FormatBaseN(8 + (InputBaseN(Mid(local.hex, 17, 1), 16) MOD 4), 16);
		return Mid(local.hex, 1, 8) & "-" & Mid(local.hex, 9, 4) & "-4" & Mid(local.hex, 14, 3) & "-" & local.variant & Mid(local.hex, 18, 3) & "-" & Mid(local.hex, 21, 12);
	}


	public array function $splitOutsideFunctions(required string list, required string splitBy) {
		local.rv = [];
		local.temp = "";
		local.insideFunction = false;
		local.bracketCount = 0;

		for (local.i = 1; i <= Len(arguments.list); i++) {
			local.char = Mid(arguments.list, i, 1);

			// Check if we are entering or exiting a function's parentheses
			if (local.char == "(") {
				local.bracketCount++;
			} else if (local.char == ")") {
				local.bracketCount--;
			}

			// Determine if we are inside a function (any content enclosed by parentheses)
			if (local.bracketCount > 0) {
				local.insideFunction = true;
			} else if (local.bracketCount == 0) {
				local.insideFunction = false;
			}

			// Split based on commas outside functions
			if (local.char == arguments.splitBy && !local.insideFunction) {
				ArrayAppend(local.rv, Trim(local.temp));
				local.temp = "";
			} else {
				local.temp &= local.char;
			}
		}

		// Append the final segment
		if (Len(Trim(local.temp))) {
			ArrayAppend(local.rv, Trim(local.temp));
		}

		return local.rv;
	}


	/**
	 * Normalizes a nested key path by converting bracket notation (e.g., `form[user][email]`) to dot notation (e.g., `form.user.email`).
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @path The key path to normalize.
	 */
	public string function $normalizePath(required string path) {
		local.norm = arguments.path;
		local.norm = ReReplace(local.norm, "\[(.*?)\]", ".\1", "all");
		local.norm = ReReplace(local.norm, "^\.", "", "one");
		return local.norm;
	}

/**
 * True when the engine can open the named datasource. The app test
 * runner checks this before refusing a missing `<datasource>_test`, because a
 * datasource registered at server level (the Lucee admin, `lucee.json`
 * `configuration.datasources`, the CF Administrator, CommandBox cfconfig) is
 * not listed in GetApplicationMetaData().datasources. Any failure, including
 * an engine whose cfdbinfo can't answer, means "not reachable", so the runner
 * still fails closed. Only the named datasource is touched.
 */
public boolean function $dataSourceIsReachable(required string name) {
	var state = {reachable = false};
	if (!Len(Trim(arguments.name))) {
		return false;
	}
	try {
		$dbinfo(type = "version", datasource = arguments.name);
		state.reachable = true;
	} catch (any e) {
		state.reachable = false;
	}
	return state.reachable;
}

/**
 * Internal. Which datasource an app test run may use, by the same rules as the
 * built-in runner (`vendor/wheels/tests/app-runner.cfm`):
 * - an explicit, valid `useTestDB=false` runs on the primary datasource (intentional);
 * - otherwise `<primary>_test` is used when it is registered or reachable ("swap");
 * - otherwise an omitted `useTestDB` with `allowTestsAgainstPrimaryDatasource=true`
 *   runs on the primary datasource with a warning;
 * - anything else is refused.
 * Returns `{action: swap|primary|refuse, primary, candidate, target, warn}`.
 * `candidateRegistered` is probed when not passed (passed by specs).
 */
public struct function $testDataSourceDecision(
	required string primary,
	required struct requestUrl,
	candidateRegistered
) {
	local.rv = {
		action = "refuse",
		primary = arguments.primary,
		candidate = arguments.primary & "_test",
		target = "",
		warn = false
	};
	local.paramPresent = StructKeyExists(arguments.requestUrl, "useTestDB");
	local.validBoolean = local.paramPresent && IsBoolean(arguments.requestUrl.useTestDB);
	if (local.validBoolean && !arguments.requestUrl.useTestDB) {
		local.rv.action = "primary";
		local.rv.target = arguments.primary;
		return local.rv;
	}
	if (!StructKeyExists(arguments, "candidateRegistered") || IsNull(arguments.candidateRegistered)) {
		arguments.candidateRegistered = $testDataSourceRegistered(local.rv.candidate);
	}
	if (arguments.candidateRegistered) {
		local.rv.action = "swap";
		local.rv.target = local.rv.candidate;
		return local.rv;
	}
	local.allowPrimary = StructKeyExists(application.wheels, "allowTestsAgainstPrimaryDatasource")
		&& IsBoolean(application.wheels.allowTestsAgainstPrimaryDatasource)
		&& application.wheels.allowTestsAgainstPrimaryDatasource;
	if (!local.paramPresent && local.allowPrimary) {
		local.rv.action = "primary";
		local.rv.target = arguments.primary;
		local.rv.warn = true;
	}
	return local.rv;
}

/**
 * Internal. True when this request belongs to the app test run in progress: it carries
 * that run's token (`wheelsTestRun`). Such a request runs inside the run, so it must not
 * wait on the runner lock the run holds, nor swap or restore the datasource again.
 */
public boolean function $isTestRunReentry(required struct requestUrl) {
	local.activeRunToken = StructKeyExists(application, "$$$appTestRunToken") ? application["$$$appTestRunToken"] : "";
	local.requestRunToken = (StructKeyExists(arguments.requestUrl, "wheelsTestRun") && IsSimpleValue(arguments.requestUrl.wheelsTestRun))
		? arguments.requestUrl.wheelsTestRun
		: "";
	return Len(local.activeRunToken) > 0 && Compare(local.requestRunToken, local.activeRunToken) == 0;
}

/**
 * Internal. Defaults `coreTestDataSourceName` to `dataSourceName` when the settings did not
 * set it. onApplicationStart calls it after the settings files load, so the default follows
 * the dataSourceName they set rather than the one derived from the app's folder before them.
 */
public void function $defaultCoreTestDataSourceName(required struct settings) {
	if (!StructKeyExists(arguments.settings, "coreTestDataSourceName")) {
		arguments.settings.coreTestDataSourceName = arguments.settings.dataSourceName;
	}
}

/**
 * Internal. Which datasource the framework's own test runners (the core runner and the
 * RocketUnit runner) use. `?db=` naming one of `testDbList` selects `wheelstestdb_<db>`, and
 * the `|datasourceName|` placeholder selects `wheelstestdb`, as before. A
 * `coreTestDataSourceName` other than the app's primary datasource is used as it is when it
 * exists, and refused when it does not. Only
 * when the run would otherwise use the app's primary datasource does the app-test rule apply
 * ($testDataSourceDecision): `<primary>_test`, the primary datasource only for an explicit
 * useTestDB=false (never through allowTestsAgainstPrimaryDatasource), or refused.
 * Returns `{action: use|swap|primary|refuse, target, decision, message}`; `message` explains a
 * refusal.
 */
public struct function $coreTestDataSource(
	required string primary,
	required string coreName,
	required struct requestUrl,
	string testDbList = "mysql,sqlserver,sqlserver_cicd,postgres,h2,oracle,sqlite,cockroachdb",
	candidateRegistered,
	targetRegistered
) {
	local.rv = {action = "use", target = "", decision = {}, ignoredAllowPrimary = false, message = ""};
	if (
		StructKeyExists(arguments.requestUrl, "db")
		&& IsSimpleValue(arguments.requestUrl.db)
		&& ListFind(arguments.testDbList, arguments.requestUrl.db)
	) {
		local.rv.target = ListFind("sqlserver,sqlserver_cicd", arguments.requestUrl.db) ? "wheelstestdb_sqlserver" : "wheelstestdb_" & arguments.requestUrl.db;
		return local.rv;
	}
	if (arguments.coreName == "|datasourceName|") {
		local.rv.target = "wheelstestdb";
		return local.rv;
	}
	if (Compare(arguments.coreName, arguments.primary) != 0) {
		local.registered = (StructKeyExists(arguments, "targetRegistered") && !IsNull(arguments.targetRegistered))
			? arguments.targetRegistered
			: $testDataSourceRegistered(name = arguments.coreName);
		if (!local.registered) {
			local.rv.action = "refuse";
			local.rv.decision = {primary = arguments.primary, candidate = arguments.coreName};
			local.rv.message = "The framework test suite is set to use the datasource '" & arguments.coreName
				& "' (coreTestDataSourceName), which does not exist. Set coreTestDataSourceName in config/settings.cfm, create '"
				& arguments.coreName & "', or pass ?db= to use a wheelstestdb_<db> datasource.";
			return local.rv;
		}
		local.rv.target = arguments.coreName;
		return local.rv;
	}
	local.decisionArgs = {primary = arguments.primary, requestUrl = arguments.requestUrl};
	if (StructKeyExists(arguments, "candidateRegistered") && !IsNull(arguments.candidateRegistered)) {
		local.decisionArgs.candidateRegistered = arguments.candidateRegistered;
	}
	local.rv.decision = $testDataSourceDecision(argumentCollection = local.decisionArgs);
	// allowTestsAgainstPrimaryDatasource is a compatibility setting for app tests from
	// older CLIs. The framework's suite (and its populate.cfm, which drops and recreates
	// tables) never uses it: only an explicit useTestDB=false reaches the primary.
	if (local.rv.decision.action == "primary" && local.rv.decision.warn) {
		local.rv.decision.action = "refuse";
		local.rv.decision.warn = false;
		local.rv.ignoredAllowPrimary = true;
		try {
			WriteLog(
				file = "wheels",
				type = "warning",
				text = "The framework test suite ignores allowTestsAgainstPrimaryDatasource: it does not run on the primary datasource '" & arguments.primary & "' unless the request passes useTestDB=false."
			);
		} catch (any e) {
		}
	}
	local.rv.action = local.rv.decision.action;
	local.rv.target = local.rv.decision.action == "refuse" ? "" : local.rv.decision.target;
	if (local.rv.action == "refuse") {
		local.rv.message = "The framework test suite would run on this app's primary datasource '" & local.rv.decision.primary
			& "'. Pass ?db= to use a wheelstestdb_<db> datasource, create '" & local.rv.decision.candidate
			& "', or run against the primary datasource intentionally with useTestDB=false.";
	}
	return local.rv;
}

/**
 * Internal. True when `name` is in the application's datasources or the engine can
 * open it (a datasource registered at server level is not in the application metadata).
 */
public boolean function $testDataSourceRegistered(required string name) {
	local.meta = GetApplicationMetaData();
	if (
		StructKeyExists(local.meta, "datasources")
		&& IsStruct(local.meta.datasources)
		&& StructKeyExists(local.meta.datasources, arguments.name)
	) {
		return true;
	}
	return $dataSourceIsReachable(name = arguments.name);
}

/**
 * Internal. Points a project test runner (`tests/runner.cfm`) at the datasource
 * `decision` chose and returns what to restore with `$endTestRunDataSource()`.
 * Runners copied from older Wheels releases set `dataSourceName` from
 * `coreTestDataSourceName`, so both are pointed at the test datasource. Records the
 * run's token (so re-entrant requests from the run skip the runner lock) and the swap
 * markers $recoverStrandedTestRun() uses if the run dies before it restores.
 */
public struct function $beginTestRunDataSource(required struct decision) {
	local.saved = {
		dataSourceName = application.wheels.dataSourceName,
		hasCoreTestDataSourceName = StructKeyExists(application.wheels, "coreTestDataSourceName"),
		coreTestDataSourceName = StructKeyExists(application.wheels, "coreTestDataSourceName") ? application.wheels.coreTestDataSourceName : ""
	};
	if (!StructKeyExists(request, "wheels")) {
		request.wheels = {};
	}
	request.wheels.$testRunnerOuter = true;
	request.wheels.$testDataSourceDecision = arguments.decision;
	application["$$$appTestRunToken"] = CreateUUID();
	$markTestRunSwap(original = local.saved.dataSourceName);
	if (arguments.decision.action == "swap") {
		application.wheels.dataSourceName = arguments.decision.target;
		application.wheels.coreTestDataSourceName = arguments.decision.target;
		if (StructKeyExists(application.wheels, "models")) {
			StructClear(application.wheels.models);
		}
		request.wheels.$testRunPreSwap = {original = arguments.decision.primary, target = arguments.decision.target};
	}
	return local.saved;
}

/**
 * Internal. Restores what `$beginTestRunDataSource()` changed. Called from a
 * `finally` block, so it does all of its own work (no loops in the caller).
 */
public void function $endTestRunDataSource(required struct saved) {
	if (Compare(application.wheels.dataSourceName, arguments.saved.dataSourceName) != 0) {
		application.wheels.dataSourceName = arguments.saved.dataSourceName;
		if (StructKeyExists(application.wheels, "models")) {
			StructClear(application.wheels.models);
		}
	}
	if (arguments.saved.hasCoreTestDataSourceName) {
		application.wheels.coreTestDataSourceName = arguments.saved.coreTestDataSourceName;
	} else {
		StructDelete(application.wheels, "coreTestDataSourceName");
	}
	$clearTestRunSwapMarkers();
	if (StructKeyExists(request, "wheels")) {
		StructDelete(request.wheels, "$testRunnerOuter");
		StructDelete(request.wheels, "$testDataSourceDecision");
		StructDelete(request.wheels, "$testRunPreSwap");
	}
}

/**
 * Internal. Records, before a test run changes the datasource settings, what they were and
 * when the run must have ended: the run's request timeout plus a margin, after which a
 * request that still finds the markers knows the run died before restoring them.
 */
public void function $markTestRunSwap(required string original) {
	application.$$$appTestOriginalDataSource = arguments.original;
	application.$$$appTestOriginalCoreDataSource = {
		exists = StructKeyExists(application.wheels, "coreTestDataSourceName"),
		value = StructKeyExists(application.wheels, "coreTestDataSourceName") ? application.wheels.coreTestDataSourceName : ""
	};
	application.$$$appTestRunDeadline = DateAdd("s", Max(1800, $getRequestTimeout()) + 300, Now());
}

/**
 * Internal. Moves a running test run's deadline forward (from `from`, normally Now()).
 * WheelsTest calls this as it builds each spec bundle, so a run that is still building
 * bundles is never taken for a dead one and restored to the primary datasource mid-run.
 */
public void function $extendTestRunDeadline(required date from) {
	if (StructKeyExists(application, "$$$appTestRunDeadline")) {
		application.$$$appTestRunDeadline = DateAdd("s", Max(1800, $getRequestTimeout()) + 300, arguments.from);
	}
}

/**
 * Internal. Removes the markers a test run set, once it has restored the settings.
 */
public void function $clearTestRunSwapMarkers() {
	StructDelete(application, "$$$appTestOriginalDataSource");
	StructDelete(application, "$$$appTestOriginalCoreDataSource");
	StructDelete(application, "$$$appTestRunDeadline");
	StructDelete(application, "$$$appTestRunToken");
}

/**
 * Internal. Restores the datasource settings a test run changed when that run died
 * before restoring them (its request was killed, so its finally block never ran).
 * `force` is for a caller that holds the test-runner lock, which proves no run is in
 * progress; otherwise the markers count as stranded only after the run's deadline.
 * Returns true when it restored something.
 */
public boolean function $recoverStrandedTestRun(boolean force = false) {
	if (!StructKeyExists(application, "$$$appTestOriginalDataSource")) {
		return false;
	}
	if (
		!arguments.force
		&& (!StructKeyExists(application, "$$$appTestRunDeadline") || DateCompare(Now(), application.$$$appTestRunDeadline) <= 0)
	) {
		return false;
	}
	local.original = application.$$$appTestOriginalDataSource;
	if (Compare(application.wheels.dataSourceName, local.original) != 0) {
		application.wheels.dataSourceName = local.original;
		if (StructKeyExists(application.wheels, "models")) {
			StructClear(application.wheels.models);
		}
	}
	if (StructKeyExists(application, "$$$appTestOriginalCoreDataSource")) {
		if (application.$$$appTestOriginalCoreDataSource.exists) {
			application.wheels.coreTestDataSourceName = application.$$$appTestOriginalCoreDataSource.value;
		} else {
			StructDelete(application.wheels, "coreTestDataSourceName");
		}
	}
	$clearTestRunSwapMarkers();
	try {
		WriteLog(
			file = "wheels",
			type = "warning",
			text = "Restored the datasource '" & local.original & "' left switched by a test run that did not finish."
		);
	} catch (any e) {
	}
	return true;
}

/**
 * Internal. Marks a test run that uses the app's primary datasource because
 * allowTestsAgainstPrimaryDatasource allows it: a response header and a warning in wheels.log.
 */
public void function $warnTestsOnPrimaryDataSource(required struct decision) {
	cfheader(name = "X-Wheels-Test-Database", value = "primary");
	try {
		WriteLog(
			file = "wheels",
			type = "warning",
			text = "App tests are running against the PRIMARY datasource '" & arguments.decision.primary & "' because allowTestsAgainstPrimaryDatasource=true and '" & arguments.decision.candidate & "' is not registered. Test writes reach the real database."
		);
	} catch (any e) {
	}
}

/**
 * Internal. The JSON body for a refused app test run.
 */
public struct function $testDataSourceRefusal(required struct decision) {
	return {
		success = false,
		error = "Test database not available",
		message = "App tests default to the '" & arguments.decision.candidate & "' datasource, which is not registered. Create it; or run against '"
			& arguments.decision.primary & "' intentionally with `wheels test --no-test-db` (URL: useTestDB=false); or, for older CLIs that cannot send useTestDB=false, "
			& "set(allowTestsAgainstPrimaryDatasource=true) in config/settings.cfm. "
			& "If tests/runner.cfm was copied from an older Wheels release, replace it with the runner `wheels new` creates (it includes wheels/tests/app-runner.cfm).",
		datasource = arguments.decision.primary,
		candidate = arguments.decision.candidate
	};
}

/**
 * Internal. The message an app test run reports when TestBox did not finish. A run
 * stopped by the request timeout says so, with the limit, so it is not read as a
 * failure of the specs themselves.
 */
public string function $testRunFailureMessage(required any runErr) {
	local.message = StructKeyExists(arguments.runErr, "message") ? arguments.runErr.message : "";
	local.type = StructKeyExists(arguments.runErr, "type") ? arguments.runErr.type : "";
	if (FindNoCase("timeout", local.message & " " & local.type)) {
		return "The test run hit the request timeout (" & $getRequestTimeout() & " seconds) and was stopped before it finished. " & local.message;
	}
	return local.message;
}
</cfscript>
