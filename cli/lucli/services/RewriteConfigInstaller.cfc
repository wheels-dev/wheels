/**
 * Project-level rewrite.config provisioning helper for `wheels start`.
 *
 * LuCLI's CatalinaBaseConfigGenerator emits a bundled-default rewrite.config
 * when the project doesn't ship its own override. That default uses a narrow
 * static-dir allow-list (`images|css|js|fonts|assets|static`) and negated
 * RewriteCond chains — neither tolerates 3.x-conventional layouts like
 * `/miscellaneous/`, `/javascripts/`, `/stylesheets/`, `/files/`, so every
 * static asset 404s when a 3.x app boots under Wheels 4.0 for the first
 * time. See issue #2626.
 *
 * `wheels new` already drops `cli/lucli/templates/app/rewrite.config` into
 * fresh apps. For 3.x → 4.0 upgrades the project has no rewrite.config, so
 * the buggy bundled default fires. This installer closes that gap by
 * copying the working template into the project root the first time
 * `wheels start` runs. Existing user-authored rewrite.config files are
 * left untouched.
 *
 * Isolated from Module.cfc so tests can exercise the behavior without
 * instantiating the full LuCLI module.
 */
component {

	public function init() {
		return this;
	}

	/**
	 * Copy the working rewrite.config template into the project root if the
	 * project doesn't already have one. Idempotent: a second call with an
	 * existing project-level rewrite.config is a no-op.
	 *
	 * Returns a struct describing the outcome:
	 *   { installed: true,  path: "<projectRoot>/rewrite.config" }       — wrote the file
	 *   { installed: false, reason: "already-present" }                  — user shipped their own
	 *   { installed: false, reason: "missing-project-root" }             — bad input
	 *   { installed: false, reason: "missing-template" }                 — template not found
	 *   { installed: false, reason: "write-failed", error: "..." }       — IO error
	 *
	 * @projectRoot     Absolute path to the project root (where Application.cfc
	 *                  lives). Empty path → returns installed=false.
	 * @sourceTemplate  Absolute path to the working rewrite.config template
	 *                  inside the wheels module distribution (typically
	 *                  cli/lucli/templates/app/rewrite.config). Missing file
	 *                  → returns installed=false without touching the project.
	 */
	public struct function install(
		required string projectRoot,
		required string sourceTemplate
	) {
		if (!len(arguments.projectRoot) || !directoryExists(arguments.projectRoot)) {
			return { installed: false, reason: "missing-project-root" };
		}

		var dest = arguments.projectRoot & "/rewrite.config";
		if (fileExists(dest)) {
			return { installed: false, reason: "already-present" };
		}

		if (!len(arguments.sourceTemplate) || !fileExists(arguments.sourceTemplate)) {
			return { installed: false, reason: "missing-template" };
		}

		try {
			fileCopy(arguments.sourceTemplate, dest);
			return { installed: true, path: dest };
		} catch (any e) {
			return { installed: false, reason: "write-failed", error: e.message };
		}
	}

}
