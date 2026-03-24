/**
 * Lightweight semver parsing and comparison utility for plugin dependency resolution.
 * Supports standard operators: =, >, >=, <, <=, ^ (compatible), ~ (patch-level).
 * Space-separated constraints are ANDed together (e.g., ">=1.0.0 <2.0.0").
 */
component output="false" {

	/**
	 * Parses a version string into a struct with major, minor, patch components.
	 * Strips leading "v" prefix, defaults missing components to 0.
	 * Pre-release labels (e.g., "-beta.1") are stored but ignored in comparisons.
	 *
	 * @version The version string to parse (e.g., "1.2.3", "v2.0", "1.0.0-beta.1")
	 * @return Struct with keys: major, minor, patch, preRelease, raw
	 */
	public struct function parse(required string version) {
		local.v = Trim(arguments.version);
		// Strip leading "v" or "V"
		if (Left(local.v, 1) == "v" || Left(local.v, 1) == "V") {
			local.v = Mid(local.v, 2, Len(local.v) - 1);
		}
		// Separate pre-release label if present
		local.preRelease = "";
		if (Find("-", local.v)) {
			local.preRelease = Mid(local.v, Find("-", local.v) + 1, Len(local.v));
			local.v = Left(local.v, Find("-", local.v) - 1);
		}
		// Also strip build metadata (+)
		if (Find("+", local.v)) {
			local.v = Left(local.v, Find("+", local.v) - 1);
		}
		local.parts = ListToArray(local.v, ".");
		local.result = {
			major = ArrayLen(local.parts) >= 1 ? Val(local.parts[1]) : 0,
			minor = ArrayLen(local.parts) >= 2 ? Val(local.parts[2]) : 0,
			patch = ArrayLen(local.parts) >= 3 ? Val(local.parts[3]) : 0,
			preRelease = local.preRelease,
			raw = arguments.version
		};
		return local.result;
	}

	/**
	 * Compares two parsed or unparsed versions.
	 *
	 * @v1 First version (string or parsed struct)
	 * @v2 Second version (string or parsed struct)
	 * @return -1 if v1 < v2, 0 if equal, 1 if v1 > v2
	 */
	public numeric function compare(required any v1, required any v2) {
		local.a = IsStruct(arguments.v1) ? arguments.v1 : this.parse(arguments.v1);
		local.b = IsStruct(arguments.v2) ? arguments.v2 : this.parse(arguments.v2);
		if (local.a.major != local.b.major) {
			return local.a.major > local.b.major ? 1 : -1;
		}
		if (local.a.minor != local.b.minor) {
			return local.a.minor > local.b.minor ? 1 : -1;
		}
		if (local.a.patch != local.b.patch) {
			return local.a.patch > local.b.patch ? 1 : -1;
		}
		return 0;
	}

	/**
	 * Evaluates whether a version satisfies a single constraint expression.
	 * Supports: =, >, >=, <, <=, ^ (compatible-with), ~ (approximately).
	 * A bare version string (no operator) is treated as exact match (=).
	 *
	 * @version The version to check (string or parsed struct)
	 * @constraint A single constraint expression (e.g., ">=1.0.0", "^2.3.0", "~1.2.0")
	 * @return True if the version satisfies the constraint
	 */
	public boolean function satisfies(required any version, required string constraint) {
		local.c = Trim(arguments.constraint);
		if (!Len(local.c)) {
			return true;
		}
		local.ver = IsStruct(arguments.version) ? arguments.version : this.parse(arguments.version);
		// Extract operator and target version
		local.operator = "";
		local.targetStr = local.c;
		if (Left(local.c, 2) == ">=" || Left(local.c, 2) == "<=") {
			local.operator = Left(local.c, 2);
			local.targetStr = Trim(Mid(local.c, 3, Len(local.c) - 2));
		} else if (Left(local.c, 1) == ">" || Left(local.c, 1) == "<" || Left(local.c, 1) == "=") {
			local.operator = Left(local.c, 1);
			local.targetStr = Trim(Mid(local.c, 2, Len(local.c) - 1));
		} else if (Left(local.c, 1) == "^") {
			return $satisfiesCaret(local.ver, Trim(Mid(local.c, 2, Len(local.c) - 1)));
		} else if (Left(local.c, 1) == "~") {
			return $satisfiesTilde(local.ver, Trim(Mid(local.c, 2, Len(local.c) - 1)));
		}
		// Default: exact match
		if (!Len(local.operator)) {
			local.operator = "=";
		}
		local.target = this.parse(local.targetStr);
		// Use this.compare() to avoid collision with CFML built-in compare()
		local.cmp = this.compare(local.ver, local.target);
		switch (local.operator) {
			case ">=":
				return local.cmp >= 0;
			case "<=":
				return local.cmp <= 0;
			case ">":
				return local.cmp > 0;
			case "<":
				return local.cmp < 0;
			case "=":
				return local.cmp == 0;
		}
		return false;
	}

	/**
	 * Evaluates whether a version satisfies ALL constraints in a space-separated string.
	 * Each constraint is ANDed: ">=1.0.0 <2.0.0" means version must satisfy both.
	 *
	 * @version The version to check (string or parsed struct)
	 * @constraints Space-separated constraint expressions
	 * @return True if all constraints are satisfied
	 */
	public boolean function satisfiesAll(required any version, required string constraints) {
		local.ver = IsStruct(arguments.version) ? arguments.version : this.parse(arguments.version);
		local.parts = ListToArray(Trim(arguments.constraints), " ");
		for (local.part in local.parts) {
			if (!this.satisfies(local.ver, local.part)) {
				return false;
			}
		}
		return true;
	}

	/**
	 * Formats a parsed version struct back to a string.
	 *
	 * @version Parsed version struct
	 * @return Formatted version string (e.g., "1.2.3")
	 */
	public string function format(required struct version) {
		return arguments.version.major & "." & arguments.version.minor & "." & arguments.version.patch;
	}

	/**
	 * Caret (^) — compatible with version. Allows changes that do not modify
	 * the left-most non-zero digit: ^1.2.3 := >=1.2.3 <2.0.0,
	 * ^0.2.3 := >=0.2.3 <0.3.0, ^0.0.3 := >=0.0.3 <0.0.4
	 */
	private boolean function $satisfiesCaret(required struct ver, required string targetStr) {
		local.target = this.parse(arguments.targetStr);
		// Must be >= target
		if (this.compare(arguments.ver, local.target) < 0) {
			return false;
		}
		// Upper bound depends on left-most non-zero digit
		if (local.target.major != 0) {
			// ^1.2.3 → <2.0.0
			return arguments.ver.major == local.target.major;
		} else if (local.target.minor != 0) {
			// ^0.2.3 → <0.3.0
			return arguments.ver.major == 0 && arguments.ver.minor == local.target.minor;
		} else {
			// ^0.0.3 → <0.0.4
			return arguments.ver.major == 0 && arguments.ver.minor == 0 && arguments.ver.patch == local.target.patch;
		}
	}

	/**
	 * Tilde (~) — approximately equivalent. Allows patch-level changes:
	 * ~1.2.3 := >=1.2.3 <1.3.0, ~1.2 := >=1.2.0 <1.3.0
	 */
	private boolean function $satisfiesTilde(required struct ver, required string targetStr) {
		local.target = this.parse(arguments.targetStr);
		// Must be >= target
		if (this.compare(arguments.ver, local.target) < 0) {
			return false;
		}
		// Same major and minor
		return arguments.ver.major == local.target.major && arguments.ver.minor == local.target.minor;
	}

}
