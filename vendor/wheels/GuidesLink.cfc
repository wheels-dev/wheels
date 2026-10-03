/**
 * Builds guides.wheels.dev links for the running framework version (#3931).
 *
 * The guides are published per minor version (`v4-1-0/...`). The segment is
 * derived from the framework version and clamped to the guide trees that exist:
 * never older than 4.0, never newer than `variables.latest` (a version whose
 * guides aren't cut yet would 404). A version that can't be parsed, such as an
 * unstamped dev checkout, gets the latest tree. GuidesLinkSpec fails when any
 * tree under web/sites/guides/src/content/docs/ is newer than `latest`, including
 * one still marked 'snapshot' (in development): code built from that branch ships
 * as that minor, so its links, such as an upgrade check's "upgrading/" page, must
 * reach that minor's guides. Bump `latest` when a version's guides tree is cut.
 * cli/lucli/services/GuidesLink.cfc carries the same logic for the CLI.
 */
component {

	variables.latest = "4.2";
	variables.oldest = "4.0";

	/**
	 * The full URL for a guides path, e.g. link("upgrading/3x-to-4x/").
	 */
	public string function link(required string path, string version = $frameworkVersion()) {
		return "https://guides.wheels.dev/" & segment(arguments.version) & "/" & arguments.path;
	}

	/**
	 * The guides version segment (`v4-1-0`) for a framework version.
	 */
	public string function segment(string version = "") {
		local.match = ReFind("^([0-9]+)\.([0-9]+)", arguments.version, 1, true);
		local.target = variables.latest;
		// Major version 0 is an unstamped dev build (0.0.0-dev): treat it as unknown.
		if (ArrayLen(local.match.pos) >= 3 && local.match.pos[1] > 0 && Val(Mid(arguments.version, local.match.pos[2], local.match.len[2])) > 0) {
			local.target = Mid(arguments.version, local.match.pos[2], local.match.len[2])
				& "." & Mid(arguments.version, local.match.pos[3], local.match.len[3]);
			if ($compareMinor(local.target, variables.latest) > 0) {
				local.target = variables.latest;
			} else if ($compareMinor(local.target, variables.oldest) < 0) {
				local.target = variables.oldest;
			}
		}
		return "v" & ListFirst(local.target, ".") & "-" & ListLast(local.target, ".") & "-0";
	}

	/**
	 * The newest guides version this build links to (major.minor).
	 */
	public string function latestVersion() {
		return variables.latest;
	}

	/**
	 * -1, 0 or 1 comparing two major.minor strings numerically.
	 */
	public numeric function $compareMinor(required string a, required string b) {
		local.a = ListFirst(arguments.a, ".") * 1000 + ListLast(arguments.a, ".");
		local.b = ListFirst(arguments.b, ".") * 1000 + ListLast(arguments.b, ".");
		return local.a == local.b ? 0 : (local.a > local.b ? 1 : -1);
	}

	/**
	 * The running framework version, or "" when it isn't known yet.
	 */
	public string function $frameworkVersion() {
		if (IsDefined("application.$wheels.version") && IsSimpleValue(application.$wheels.version)) {
			return application.$wheels.version;
		}
		if (IsDefined("application.wheels.version") && IsSimpleValue(application.wheels.version)) {
			return application.wheels.version;
		}
		return "";
	}

}
