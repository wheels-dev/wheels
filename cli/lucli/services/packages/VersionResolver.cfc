/**
 * Picks a version from a manifest's versions[] array, filtering by
 * framework compatibility and an optional user pin.
 *
 * Uses the LuCLI-local copy of SemVer (mirrored from vendor/wheels/SemVer.cfc)
 * so this resolves cleanly in the CLI's runtime context. The dotted path
 * `wheels.SemVer` requires a `/wheels` mapping that's only present inside
 * a Wheels application's HTTP request context — not when the CLI is
 * dispatching from LuCLI's LuceeScriptEngine. See the Phase 7 follow-on
 * regression that surfaced after #2309.
 *
 * Framework version comes from wheels.Global::$readFrameworkVersion() —
 * the caller passes it in so this component stays pure and testable
 * without needing an application scope.
 *
 * Pre-releases: pick() only considers versions with a pre-release label
 * (e.g. "1.2.0-rc.1") when the pin itself names a pre-release
 * ("1.2.0-rc.1", ">=1.2.0-beta.1"). With no pin, or a pin made only of
 * release versions ("1.2.0", "^1.0.0"), the highest stable release wins.
 * The runtime compatibility gate compares the framework version without
 * its pre-release label, so a snapshot build such as "4.1.2-snapshot.500"
 * satisfies ">=4.1.2" just like the "4.1.2" release it was cut from.
 * A dev runtime (base version 0.0.0, e.g. the "0.0.0-dev" sentinel a source
 * checkout reports) skips the gate: it is permissive, not incompatible.
 */
component {

	public VersionResolver function init(any semver = "") {
		variables.semver = IsObject(arguments.semver)
			? arguments.semver
			: new modules.wheels.services.SemVer();
		return this;
	}

	/**
	 * @manifest  Parsed manifest struct (has `versions` array).
	 * @runtime   Current framework version string (e.g. "4.0.0").
	 * @pin       Optional user pin — either an exact version ("1.2.3")
	 *            or a SemVer constraint ("^1.0.0", ">=1.0 <2.0"), or "".
	 *            Pre-release versions are only eligible when the pin names
	 *            one (see the component header).
	 * @return    Chosen version entry struct (element of versions[]).
	 * @throws    Wheels.Packages.NoCompatibleVersion when nothing matches.
	 */
	public struct function pick(
		required struct manifest,
		required string runtime,
		string pin = ""
	) {
		if (!StructKeyExists(arguments.manifest, "versions")
			|| !IsArray(arguments.manifest.versions)
			|| !ArrayLen(arguments.manifest.versions)) {
			Throw(
				type = "Wheels.Packages.NoVersions",
				message = "Manifest has no versions to choose from."
			);
		}

		local.runtimeBase = $runtimeBase(arguments.runtime);
		local.devRuntime = local.runtimeBase == "0.0.0";
		local.allowPreRelease = $pinNamesPreRelease(arguments.pin);
		local.candidates = [];
		for (local.entry in arguments.manifest.versions) {
			if (!StructKeyExists(local.entry, "version") || !Len(local.entry.version)) {
				continue;
			}
			// Stable releases only, unless the pin explicitly asks for a pre-release.
			if (!local.allowPreRelease
				&& Len(variables.semver.parse(local.entry.version).preRelease)) {
				continue;
			}
			// Framework compatibility gate.
			local.constraint = StructKeyExists(local.entry, "wheelsVersion")
				? Trim(local.entry.wheelsVersion)
				: "";
			if (Len(local.constraint) && !local.devRuntime
				&& !variables.semver.satisfiesAll(local.runtimeBase, local.constraint)) {
				continue;
			}
			// User pin gate.
			if (Len(arguments.pin)
				&& !variables.semver.satisfiesAll(local.entry.version, arguments.pin)) {
				continue;
			}
			ArrayAppend(local.candidates, local.entry);
		}

		if (!ArrayLen(local.candidates)) {
			local.known = [];
			for (local.any in arguments.manifest.versions) {
				ArrayAppend(local.known, local.any.version ?: "?");
			}
			Throw(
				type = "Wheels.Packages.NoCompatibleVersion",
				message = "No version of '#(arguments.manifest.name ?: "package")#' "
					& "satisfies runtime '#arguments.runtime#'"
					& (Len(arguments.pin) ? " and pin '#arguments.pin#'" : "") & ".",
				extendedInfo = "Available versions: " & ArrayToList(local.known, ", ")
					& (local.allowPreRelease ? "" : " (pre-release versions are only considered "
						& "when the pin names one, e.g. name@1.2.0-rc.1)")
			);
		}

		// Highest SemVer wins.
		local.best = local.candidates[1];
		for (local.i = 2; local.i <= ArrayLen(local.candidates); local.i++) {
			if (variables.semver.compare(local.candidates[local.i].version, local.best.version) > 0) {
				local.best = local.candidates[local.i];
			}
		}
		return local.best;
	}

	/**
	 * Returns every version compatible with the runtime (no pin), ordered
	 * highest → lowest. Used by `wheels packages show` to display history.
	 */
	public array function compatibleVersions(
		required struct manifest,
		required string runtime
	) {
		local.compatible = [];
		if (!StructKeyExists(arguments.manifest, "versions")
			|| !IsArray(arguments.manifest.versions)) {
			return local.compatible;
		}
		local.runtimeBase = $runtimeBase(arguments.runtime);
		local.devRuntime = local.runtimeBase == "0.0.0";
		for (local.entry in arguments.manifest.versions) {
			if (!StructKeyExists(local.entry, "version") || !Len(local.entry.version)) {
				continue;
			}
			local.constraint = StructKeyExists(local.entry, "wheelsVersion")
				? Trim(local.entry.wheelsVersion)
				: "";
			if (Len(local.constraint) && !local.devRuntime
				&& !variables.semver.satisfiesAll(local.runtimeBase, local.constraint)) {
				continue;
			}
			ArrayAppend(local.compatible, local.entry);
		}
		// Sort highest first. Simple insertion sort to sidestep ArraySort
		// callback quirks across Lucee/Adobe and avoid arrow-fn parsing pitfalls.
		for (local.i = 2; local.i <= ArrayLen(local.compatible); local.i++) {
			local.cur = local.compatible[local.i];
			local.j = local.i - 1;
			while (local.j >= 1
				&& variables.semver.compare(local.compatible[local.j].version, local.cur.version) < 0) {
				local.compatible[local.j + 1] = local.compatible[local.j];
				local.j--;
			}
			local.compatible[local.j + 1] = local.cur;
		}
		return local.compatible;
	}

	/**
	 * The framework version without its pre-release label ("4.1.2-snapshot.500"
	 * → "4.1.2"). Snapshot builds carry the version of the release line they
	 * were cut from, so for compatibility they behave like that release.
	 */
	private string function $runtimeBase(required string runtime) {
		return variables.semver.format(variables.semver.parse(arguments.runtime));
	}

	/**
	 * True when any version in the pin carries a pre-release label, e.g.
	 * "1.2.0-rc.1" or ">=1.2.0-beta.1 <2.0.0". Operators are stripped before
	 * parsing each space-separated part.
	 */
	private boolean function $pinNamesPreRelease(required string pin) {
		for (local.part in ListToArray(Trim(arguments.pin), " ")) {
			local.target = REReplace(local.part, "^[\^~<>=]+", "");
			if (Len(local.target) && Len(variables.semver.parse(local.target).preRelease)) {
				return true;
			}
		}
		return false;
	}
}
