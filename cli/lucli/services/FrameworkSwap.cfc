/**
 * FrameworkSwap — apply-mode engine for `wheels upgrade` (GH #3035).
 *
 * `wheels upgrade` was check-only: the bare verb printed usage and
 * `wheels upgrade check` scanned for breaking changes, but the actual
 * framework swap was left to the user (download a zip, hand-replace
 * `vendor/wheels/`). This service supplies the missing one-command path —
 * swap the app's vendored `vendor/wheels/` for the framework bundled inside
 * the installed CLI, parking the old copy in a timestamped backup first.
 *
 * Two stages, deliberately split so the planning is side-effect-free and can
 * power both `--dry-run` and the real run from one code path:
 *
 *   plan()  — pure. Resolves source/target, sniffs both as Wheels framework
 *             dirs, enforces every safety rail (outside-app, same-dir, `--to`
 *             version match), and reports old -> new. No writes.
 *   apply()  — destructive. Atomically renames the old `vendor/wheels/` to the
 *             backup path (hard-errors if the rename fails — recovery is a
 *             single `mv`), then copies the bundled framework into place.
 *
 * Cross-engine note (CLI runs only on the bundled Lucee, but still): version
 * sniffing reads `wheels.json` (preferred) / `box.json` (legacy) via JSON
 * deserialize — no `(.+)`-spanning-newline regexes — and `renameTo()` returns
 * a boolean (it does NOT throw) on cross-filesystem moves, so we check it.
 */
component {

	public function init() {
		return this;
	}

	/**
	 * Plan a framework swap without performing it. Pure — no filesystem writes.
	 *
	 * @target      The app's vendor/wheels directory (swap destination).
	 * @source      The CLI's bundled vendor/wheels directory (swap source).
	 * @requestedTo Optional version pin. When non-blank it must exactly equal
	 *              the bundled framework version, else the plan is refused —
	 *              this CLI can only install the version it bundles (network
	 *              download of arbitrary versions is a documented follow-up).
	 * @timestamp   Backup-suffix stamp (yyyymmdd-HHmmss). Injected by the
	 *              caller so the result is deterministic and testable.
	 *
	 * Returns: {ok, reason, fromVersion, toVersion, sourcePath, targetPath,
	 *           backupPath, sameDir}. When ok is false, reason explains why and
	 *           the caller must refuse before any destructive step.
	 */
	public struct function plan(
		required string target,
		required string source,
		string requestedTo = "",
		string timestamp = ""
	) {
		var sourcePath = $normalizePath(arguments.source);
		var targetPath = $normalizePath(arguments.target);
		var result = {
			ok = false,
			reason = "",
			fromVersion = "",
			toVersion = "",
			sourcePath = sourcePath,
			targetPath = targetPath,
			backupPath = "",
			sameDir = false
		};

		// Refuse outside a Wheels app — there's no vendor/wheels to swap.
		if (!$isDir(arguments.target)) {
			result.reason = "Not in a Wheels app: no vendor/wheels directory at " & targetPath
				& ". Run wheels upgrade from the root of a Wheels application.";
			return result;
		}

		// The bundled framework source must exist (CLI install located).
		if (!$isDir(arguments.source)) {
			result.reason = "Could not locate the CLI's bundled framework source at " & sourcePath
				& ". Set WHEELS_FRAMEWORK_PATH to a valid vendor/wheels directory.";
			return result;
		}

		// Both ends must sniff as a Wheels framework dir (wheels.json/box.json).
		if (!$isFrameworkDir(arguments.target)) {
			result.reason = "Target " & targetPath
				& " is not a Wheels framework directory (no wheels.json or box.json).";
			return result;
		}
		if (!$isFrameworkDir(arguments.source)) {
			result.reason = "Bundled source " & sourcePath
				& " is not a Wheels framework directory (no wheels.json or box.json).";
			return result;
		}

		// Refuse a no-op self-swap — e.g. running inside the wheels repo
		// checkout itself, where source and target resolve to one directory.
		if ($sameCanonicalDir(arguments.source, arguments.target)) {
			result.sameDir = true;
			result.reason = "Source and target resolve to the same directory (" & targetPath
				& "). Nothing to swap — are you running inside the wheels repo checkout?";
			return result;
		}

		result.fromVersion = $readVersion(arguments.target);
		result.toVersion = $readVersion(arguments.source);

		// --to must match the bundled version exactly.
		var pin = trim(arguments.requestedTo);
		if (len(pin) && pin != result.toVersion) {
			result.reason = "Requested version " & pin & " does not match the bundled framework version "
				& result.toVersion & ". This CLI can only install the version it bundles;"
				& " network download of arbitrary versions is a follow-up.";
			return result;
		}

		var stamp = len(trim(arguments.timestamp)) ? trim(arguments.timestamp) : "backup";
		result.backupPath = targetPath & ".bak-" & stamp;
		result.ok = true;
		return result;
	}

	/**
	 * Execute a plan: back up the old framework (atomic rename) and copy the
	 * bundled one into place. Throws Wheels.UpgradeApplyRefused when handed a
	 * plan that did not pass validation.
	 *
	 * @plan   A struct from plan() with ok == true.
	 * @backup When true (default) the old vendor/wheels is renamed to the
	 *         backup path before the swap; when false it is removed outright.
	 *
	 * Returns: {fromVersion, toVersion, backedUp, backupPath}.
	 */
	public struct function apply(required struct plan, boolean backup = true) {
		if (!structKeyExists(arguments.plan, "ok") || !arguments.plan.ok) {
			throw(
				type = "Wheels.UpgradeApplyRefused",
				message = structKeyExists(arguments.plan, "reason") && len(arguments.plan.reason)
					? arguments.plan.reason
					: "Refusing to apply an invalid framework-swap plan."
			);
		}

		var result = {
			fromVersion = arguments.plan.fromVersion,
			toVersion = arguments.plan.toVersion,
			backedUp = false,
			backupPath = ""
		};

		if (arguments.backup) {
			// Collision counter for rapid re-runs landing in the same second.
			var dest = $uniqueBackupPath(arguments.plan.backupPath);
			$atomicRename(arguments.plan.targetPath, dest);
			result.backupPath = dest;
			result.backedUp = true;
		} else if ($isDir(arguments.plan.targetPath)) {
			directoryDelete(arguments.plan.targetPath, true);
		}

		// Materialize the bundled framework into vendor/wheels.
		directoryCreate(arguments.plan.targetPath, true, true);
		directoryCopy(arguments.plan.sourcePath, arguments.plan.targetPath, true);

		return result;
	}

	// ═══════════════════════════════════════════════════
	//  PRIVATE — helpers
	// ═══════════════════════════════════════════════════

	private string function $normalizePath(required string p) {
		return new Helpers().normalizePath(arguments.p);
	}

	/**
	 * Java-backed directoryExists() — mirrors Module.$safeDirExists so a
	 * Windows drive-letter path never reaches Lucee's scheme detection.
	 */
	private boolean function $isDir(required string p) {
		try {
			return directoryExists(arguments.p);
		} catch (any e) {
			return createObject("java", "java.io.File").init(arguments.p).isDirectory();
		}
	}

	private boolean function $isFrameworkDir(required string dir) {
		return len($resolveManifest(arguments.dir)) > 0;
	}

	/**
	 * Resolve a directory's manifest, preferring the post-rename wheels.json
	 * over the legacy box.json. Returns the path, or "" when neither exists.
	 */
	private string function $resolveManifest(required string dir) {
		var newPath = arguments.dir & "/wheels.json";
		if (fileExists(newPath)) return newPath;
		var legacyPath = arguments.dir & "/box.json";
		if (fileExists(legacyPath)) return legacyPath;
		return "";
	}

	private string function $readVersion(required string dir) {
		var manifest = $resolveManifest(arguments.dir);
		if (!len(manifest)) return "unknown";
		try {
			var data = deserializeJSON(fileRead(manifest));
			var v = data.version ?: "";
			return len(trim(v)) ? trim(v) : "unknown";
		} catch (any e) {
			return "unknown";
		}
	}

	private boolean function $sameCanonicalDir(required string a, required string b) {
		var File = createObject("java", "java.io.File");
		try {
			return File.init(arguments.a).getCanonicalPath() == File.init(arguments.b).getCanonicalPath();
		} catch (any e) {
			return $normalizePath(arguments.a) == $normalizePath(arguments.b);
		}
	}

	/**
	 * Return a backup path that does not yet exist. Rapid re-runs within the
	 * same second would otherwise collide on the timestamp suffix.
	 */
	private string function $uniqueBackupPath(required string base) {
		if (!$isDir(arguments.base)) return arguments.base;
		var n = 2;
		while ($isDir(arguments.base & "-" & n)) {
			n++;
		}
		return arguments.base & "-" & n;
	}

	/**
	 * Atomic same-volume backup via java.io.File.renameTo. renameTo returns
	 * false (it does NOT throw) on a cross-filesystem move — check the boolean
	 * and hard-error so the user never ends up with a half-applied swap.
	 */
	private void function $atomicRename(required string from, required string to) {
		var File = createObject("java", "java.io.File");
		var ok = File.init(arguments.from).renameTo(File.init(arguments.to));
		if (!ok) {
			throw(
				type = "Wheels.UpgradeBackupFailed",
				message = "Could not back up " & arguments.from & " to " & arguments.to
					& " (atomic rename failed — likely a cross-filesystem move). Move it"
					& " manually and retry, or re-run with --nobackup."
			);
		}
	}

}
