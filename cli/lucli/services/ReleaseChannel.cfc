/**
 * Pure-function helpers for classifying Wheels CLI version strings into release
 * channels. Used by `wheels --version` (in Module.cfc) and the update-check
 * feature on `wheels new`.
 *
 * Channels and their downstream meaning:
 *
 *   stable             — installed via `brew install wheels` (or equivalent on
 *                        choco/scoop/winget). Updates only on GA releases. The
 *                        update-check hits api.github.com/repos/wheels-dev/wheels.
 *   bleeding-edge      — installed via `brew install wheels-be`. Updates on every
 *                        develop merge. The update-check hits api.github.com/repos/
 *                        wheels-dev/wheels-snapshots.
 *   release-candidate  — installed manually or via a pre-release tap during
 *                        stabilization windows. Update-check skipped (the user
 *                        opted in explicitly).
 *   development        — running from a dev checkout where @build.version@ never
 *                        got substituted, or from `LuCLI module install` of a local
 *                        path. Update-check skipped (comparing dev to released is
 *                        meaningless).
 *
 * The channel is derived purely from the version string. No env vars, no META
 * files, no on-disk state. This keeps the function unit-testable in isolation
 * and means brew/choco/scoop/winget don't need to coordinate with the CLI on a
 * channel marker — the version string IS the marker.
 */
component {

	public function init() {
		return this;
	}

	/**
	 * Classify a version string into a release channel. Returns one of:
	 * "stable", "bleeding-edge", "release-candidate", "development", or "" for
	 * unrecognized input (callers should treat "" as "skip channel-aware logic").
	 *
	 * Recognizes both the post-fix snapshot format (`-snapshot.N`) and the
	 * legacy pre-fix format (`-SNAPSHOT+N`) so users on bottles built before
	 * the SemVer separator fix still get classified correctly.
	 */
	public string function classify(required string moduleVersion) {
		var v = trim(arguments.moduleVersion);

		// Empty / placeholder / dev-checkout sentinels.
		if (
			!len(v)
			|| v == "@build.version@"
			|| v == "Version not specified"
			|| reFindNoCase("\-dev$", v)
			|| reFindNoCase("^0\.0\.0", v)
		) {
			return "development";
		}

		// Release candidates: 4.1.0-rc.1, 5.0.0-rc.3, etc.
		if (reFindNoCase("\-rc\.[0-9]+", v)) {
			return "release-candidate";
		}

		// Snapshots: 4.0.1-snapshot.1700 (post-fix) or 4.0.0-SNAPSHOT+1656 (legacy).
		// `reFindNoCase` matches case-insensitively so both spellings hit.
		if (reFindNoCase("snapshot", v)) {
			return "bleeding-edge";
		}

		// SemVer-clean MAJOR.MINOR.PATCH with no pre-release identifier → stable.
		if (reFindNoCase("^[0-9]+\.[0-9]+\.[0-9]+$", v)) {
			return "stable";
		}

		// Unrecognized — caller decides what to do. Returning "" rather than
		// throwing keeps the version output graceful for users on a custom build.
		return "";
	}

	/**
	 * Return the GitHub repo (org/name form) that hosts releases for the given
	 * channel. Used by the update-check to know which `releases/latest` endpoint
	 * to hit. Returns "" for channels that should not run an update check.
	 */
	public string function releaseRepo(required string channel) {
		switch (arguments.channel) {
			case "stable":
				return "wheels-dev/wheels";
			case "bleeding-edge":
				return "wheels-dev/wheels-snapshots";
			default:
				// release-candidate and development don't auto-check.
				return "";
		}
	}

	/**
	 * Suggest the upgrade command appropriate for the given channel and the
	 * platform we're running on. Used as the actionable hint in update-check
	 * output. The CLI doesn't actually run this — it just prints it.
	 */
	public string function upgradeCommand(required string channel) {
		var pkg = arguments.channel == "bleeding-edge" ? "wheels-be" : "wheels";

		// java.lang.System#getProperty("os.name") returns values like
		// "Mac OS X", "Linux", "Windows 10". Normalize to a small fixed set.
		var osName = "";
		try {
			var sys = createObject("java", "java.lang.System");
			var name = sys.getProperty("os.name");
			if (!isNull(name) && len(name)) {
				osName = lCase(name);
			}
		} catch (any e) {
			// fall through — return a brew hint as the safest default
		}

		if (find("windows", osName)) {
			return "scoop update " & pkg & "  (or: winget upgrade WheelsFramework." & (pkg == "wheels-be" ? "WheelsBE" : "Wheels") & ")";
		}
		// macOS or Linux — both use brew (Linuxbrew is supported, and apt/yum users
		// will have a different hint surfaced via their package-manager metadata).
		return "brew upgrade " & pkg;
	}

}
