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
		if (arguments.required && application.wheels.showErrorInformation) {
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
		if (application.wheels.showErrorInformation) {
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


	/**
	 * Generates a 36-character UUID compatible with SQL Server's uniqueidentifier.
	 *
	 * [section: Global Helpers]
	 * [category: UUID Functions]
	 *
	 * @return A valid 36-character UUID string (e.g., 123e4567-e89b-12d3-a456-426614174000)
	 */
	public string function generateUUID() {
		// Use Java UUID generator for a 36-character format
		return CreateObject("java", "java.util.UUID").randomUUID().toString();
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
</cfscript>
