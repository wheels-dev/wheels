/**
 * User-facing dispatcher for `wheels packages <verb>`.
 *
 * Verbs:
 *   list [--tag=<tag>]
 *   search <query>
 *   show <name>
 *   add <name>[@<version>] [--force]
 *   update <name> [--yes]
 *   update --all --yes
 *   remove <name>
 *
 * `add` (not `install`!) is the install verb because LuCLI's built-in
 * extension installer intercepts the literal subcommand `install`
 * across all modules — same trap that bit `wheels browser install`
 * (renamed to `wheels browser setup` in #2345). User input
 * `wheels packages install <name>` never reaches Module.cfc; LuCLI
 * runs its own dependency installer against `lucee.json` instead and
 * prints "No git or extension dependencies to install".
 *
 * Outputs plain text suitable for a terminal. Exit-code semantics are
 * the caller's job (Module.cfc throws to signal non-zero on fatal error;
 * `update --all` swallows per-package failures but throws at the end if
 * any failed, so the shell still sees a non-zero exit).
 */
component {

	public PackagesMainCli function init(
		any registry = "",
		any installer = "",
		any resolver = "",
		string runtimeVersion = ""
	) {
		variables.registry = IsObject(arguments.registry)
			? arguments.registry
			: new modules.wheels.services.packages.Registry();
		variables.installer = IsObject(arguments.installer)
			? arguments.installer
			: new modules.wheels.services.packages.Installer();
		variables.resolver = IsObject(arguments.resolver)
			? arguments.resolver
			: new modules.wheels.services.packages.VersionResolver();
		variables.runtime = Len(arguments.runtimeVersion)
			? arguments.runtimeVersion
			: $detectRuntime();
		return this;
	}

	// ── Verbs ───────────────────────────────────────────────

	public string function list(struct opts = {}) {
		local.names = variables.registry.listPackageNames();
		local.rows = [];
		for (local.name in local.names) {
			try {
				local.m = variables.registry.fetchManifest(local.name);
			} catch (any e) {
				// Don't let one bad manifest break `list` — show the name,
				// flag the failure. Matches `dnf list` behaviour on dead repos.
				ArrayAppend(local.rows, {name: local.name, tags: [], description: "<manifest unavailable>"});
				continue;
			}
			local.row = {
				name: local.m.name ?: local.name,
				tags: IsArray(local.m.tags ?: "") ? local.m.tags : [],
				description: local.m.description ?: ""
			};
			if (Len(arguments.opts.tag ?: "")) {
				if (!ArrayFindNoCase(local.row.tags, arguments.opts.tag)) {
					continue;
				}
			}
			ArrayAppend(local.rows, local.row);
		}
		if (!ArrayLen(local.rows)) {
			return "No packages found." & Chr(10);
		}
		return $renderList(local.rows);
	}

	public string function search(struct opts = {}) {
		local.query = Trim(arguments.opts.query ?: "");
		if (!Len(local.query)) {
			Throw(type = "Wheels.Packages.BadInput", message = "search requires a query: wheels packages search <query>");
		}
		local.names = variables.registry.listPackageNames();
		local.rows = [];
		for (local.name in local.names) {
			try {
				local.m = variables.registry.fetchManifest(local.name);
			} catch (any e) {
				continue;
			}
			local.haystack = LCase(
				(local.m.name ?: local.name) & " "
				& (local.m.description ?: "") & " "
				& ArrayToList(IsArray(local.m.tags ?: "") ? local.m.tags : [], " ")
			);
			if (Find(LCase(local.query), local.haystack)) {
				ArrayAppend(local.rows, {
					name: local.m.name ?: local.name,
					tags: IsArray(local.m.tags ?: "") ? local.m.tags : [],
					description: local.m.description ?: ""
				});
			}
		}
		if (!ArrayLen(local.rows)) {
			return "No packages matched '#local.query#'." & Chr(10);
		}
		return $renderList(local.rows);
	}

	public string function show(struct opts = {}) {
		local.name = Trim(arguments.opts.name ?: "");
		if (!Len(local.name)) {
			Throw(type = "Wheels.Packages.BadInput", message = "show requires a package name: wheels packages show <name>");
		}
		local.m = variables.registry.fetchManifest(local.name);
		local.buf = [];
		ArrayAppend(local.buf, local.m.name & " — " & (local.m.description ?: ""));
		if (StructKeyExists(local.m, "homepage"))      ArrayAppend(local.buf, "Homepage:      " & local.m.homepage);
		if (StructKeyExists(local.m, "documentation")) ArrayAppend(local.buf, "Documentation: " & local.m.documentation);
		if (StructKeyExists(local.m, "license"))       ArrayAppend(local.buf, "License:       " & local.m.license);
		if (IsArray(local.m.maintainers ?: "") && ArrayLen(local.m.maintainers)) {
			ArrayAppend(local.buf, "Maintainers:   " & ArrayToList(local.m.maintainers, ", "));
		}
		if (IsArray(local.m.tags ?: "") && ArrayLen(local.m.tags)) {
			ArrayAppend(local.buf, "Tags:          " & ArrayToList(local.m.tags, ", "));
		}
		if (variables.installer.isInstalled(local.name)) {
			ArrayAppend(local.buf, "Installed:     " & (Len(variables.installer.installedVersion(local.name))
				? variables.installer.installedVersion(local.name)
				: "(unknown version)"));
		}
		ArrayAppend(local.buf, "");
		ArrayAppend(local.buf, "Compatible versions (runtime #variables.runtime#):");
		local.compatible = variables.resolver.compatibleVersions(local.m, variables.runtime);
		if (!ArrayLen(local.compatible)) {
			ArrayAppend(local.buf, "  (none — this runtime is out of range for every published version)");
		} else {
			for (local.v in local.compatible) {
				ArrayAppend(local.buf, "  " & local.v.version
					& "   [wheelsVersion " & (local.v.wheelsVersion ?: "*") & "]"
					& (StructKeyExists(local.v, "publishedAt") ? "   published " & local.v.publishedAt : ""));
			}
		}
		ArrayAppend(local.buf, "");
		return ArrayToList(local.buf, Chr(10)) & Chr(10);
	}

	public string function add(struct opts = {}) {
		local.target = Trim(arguments.opts.target ?: "");
		if (!Len(local.target)) {
			Throw(type = "Wheels.Packages.BadInput", message = "add requires a package name: wheels packages add <name>[@<version>]");
		}
		local.parsed = $parseTarget(local.target);
		local.force = arguments.opts.force ?: false;
		return $doInstall(local.parsed.name, local.parsed.pin, local.force);
	}

	// `install` is preserved as an alias for any in-process callers
	// (specs, scripted clients) that haven't migrated to `add`. Note
	// that the public CLI surface — `wheels packages install <name>` —
	// never reaches this method because LuCLI's built-in extension
	// installer intercepts the literal `install` subcommand before
	// Module.cfc dispatches. See the component header.
	public string function install(struct opts = {}) {
		return add(argumentCollection = arguments);
	}

	public string function update(struct opts = {}) {
		if (arguments.opts.all ?: false) {
			return $updateAll(arguments.opts);
		}
		local.name = Trim(arguments.opts.target ?: "");
		if (!Len(local.name)) {
			Throw(type = "Wheels.Packages.BadInput", message = "update requires <name> or --all.");
		}
		if (!variables.installer.isInstalled(local.name)) {
			Throw(
				type = "Wheels.Packages.NotInstalled",
				message = "Package '#local.name#' is not installed. Use `wheels packages add #local.name#`."
			);
		}
		if (!(arguments.opts.yes ?: false)) {
			Throw(
				type = "Wheels.Packages.ConfirmationRequired",
				message = "Update is explicit. Re-run with --yes to confirm updating '#local.name#' to the latest compatible version."
			);
		}
		return $doInstall(local.name, "", true);
	}

	public string function remove(struct opts = {}) {
		local.name = Trim(arguments.opts.target ?: "");
		if (!Len(local.name)) {
			Throw(type = "Wheels.Packages.BadInput", message = "remove requires a package name.");
		}
		variables.installer.uninstall(local.name);
		return "Removed vendor/#local.name#." & Chr(10);
	}

	public string function runtime() { return variables.runtime; }

	// ── Private ─────────────────────────────────────────────

	private string function $doInstall(required string name, required string pin, required boolean force) {
		local.manifest = variables.registry.fetchManifest(arguments.name);
		local.picked = variables.resolver.pick(local.manifest, variables.runtime, arguments.pin);
		local.vendor = variables.installer.install(arguments.name, local.picked, arguments.force);
		// Activation only needs a reload, not a cold restart: an authorized
		// `wheels reload` calls applicationStop(), so the next request re-fires
		// onApplicationStart — which runs the PackageLoader ($loadPackages).
		// Verified live on Lucee 7 (see #3110). A full `wheels stop && wheels
		// start` also works but is no longer required. Caveat: a reload only
		// restarts when its password resolves; a missing/wrong password
		// silently skips the restart (#3059 / #3062).
		return "Installed " & arguments.name & "@" & local.picked.version & " → " & local.vendor & Chr(10)
			& "Run `wheels reload` (or restart) to activate it." & Chr(10);
	}

	private string function $updateAll(struct opts) {
		if (!(arguments.opts.yes ?: false)) {
			Throw(
				type = "Wheels.Packages.ConfirmationRequired",
				message = "Mass update is explicit. Re-run with --yes to confirm updating every installed package."
			);
		}
		// Discover installed packages from vendor/. We only touch dirs
		// that have a package.json — skipping vendor/wheels/ (framework).
		local.installed = $discoverInstalled();
		if (!ArrayLen(local.installed)) {
			return "No installed packages to update." & Chr(10);
		}
		local.report = [];
		local.failures = [];
		for (local.name in local.installed) {
			try {
				local.manifest = variables.registry.fetchManifest(local.name);
				local.picked = variables.resolver.pick(local.manifest, variables.runtime);
				if (variables.installer.installedVersion(local.name) == local.picked.version) {
					ArrayAppend(local.report, "  #local.name#: already at #local.picked.version#");
					continue;
				}
				variables.installer.install(local.name, local.picked, true);
				ArrayAppend(local.report, "  #local.name#: updated → #local.picked.version#");
			} catch (any e) {
				ArrayAppend(local.failures, local.name);
				ArrayAppend(local.report, "  #local.name#: FAILED (#e.message#)");
			}
		}
		local.out = "Update report:" & Chr(10) & ArrayToList(local.report, Chr(10)) & Chr(10);
		if (ArrayLen(local.failures)) {
			Throw(
				type = "Wheels.Packages.PartialUpdateFailure",
				message = "#ArrayLen(local.failures)# of #ArrayLen(local.installed)# package(s) failed to update: "
					& ArrayToList(local.failures, ", "),
				extendedInfo = local.out
			);
		}
		return local.out;
	}

	private array function $discoverInstalled() {
		local.vendorDir = ExpandPath("./vendor");
		if (!DirectoryExists(local.vendorDir)) return [];
		local.all = DirectoryList(local.vendorDir, false, "query");
		local.names = [];
		cfloop(query = local.all) {
			if (local.all.type != "Dir") continue;
			if (local.all.name == "wheels") continue;
			if (FileExists(local.vendorDir & "/" & local.all.name & "/package.json")) {
				ArrayAppend(local.names, local.all.name);
			}
		}
		return local.names;
	}

	private struct function $parseTarget(required string target) {
		local.at = Find("@", arguments.target);
		if (local.at == 1) {
			// Target starts with "@" — no name before the pin. Reject cleanly
			// rather than crashing on Left(str, 0) (a documented Lucee 7 hazard).
			Throw(
				type = "Wheels.Packages.BadInput",
				message = "Package name is required before '@'. Use: wheels packages add <name>[@<version>]"
			);
		}
		if (local.at > 1) {
			return {
				name: Left(arguments.target, local.at - 1),
				pin: Mid(arguments.target, local.at + 1, Len(arguments.target))
			};
		}
		return {name: arguments.target, pin: ""};
	}

	private string function $renderList(required array rows) {
		local.buf = [];
		local.maxName = 0;
		for (local.r in arguments.rows) {
			if (Len(local.r.name) > local.maxName) local.maxName = Len(local.r.name);
		}
		for (local.r in arguments.rows) {
			local.pad = RepeatString(" ", local.maxName - Len(local.r.name) + 2);
			local.tags = ArrayLen(local.r.tags) ? " [" & ArrayToList(local.r.tags, ", ") & "]" : "";
			ArrayAppend(local.buf, local.r.name & local.pad & local.r.description & local.tags);
		}
		return ArrayToList(local.buf, Chr(10)) & Chr(10);
	}

	private string function $detectRuntime() {
		// Three-tier fallback. The original implementation tried to
		// instantiate `wheels.Global` and call `$readFrameworkVersion()`,
		// but in the LuCLI context the only registered mapping for the
		// framework is `modules.wheels.*` — `wheels.Global` doesn't
		// resolve, so every CLI invocation fell through to the catch
		// and returned the `0.0.0-dev` sentinel. That made the package
		// system version-blind from the CLI: `wheels packages show`
		// reported every released runtime as out-of-range for every
		// published package's wheelsVersion constraint. See PR #XXXX.

		// Tier 1 — read .module-version text file (brew/chocolatey
		// installs write this at install time with the exact module
		// version). Plain text; no CFML compilation, no mapping lookup,
		// and immune to BuildInfo.cfc bugs like the self-substituting
		// sentinel issue fixed in #2368.
		try {
			local.versionFile = ExpandPath("/modules/wheels/.module-version");
			if (FileExists(local.versionFile)) {
				local.v = Trim(FileRead(local.versionFile));
				if (Len(local.v)) return local.v;
			}
		} catch (any e) {
			// ExpandPath may throw in unusual contexts (e.g. the file
			// system mapping isn't yet wired). Fall through.
		}

		// Tier 2 — instantiate the bundled BuildInfo.cfc directly via
		// the `modules.wheels.*` mapping that LuCLI guarantees. This
		// covers ForgeBox installs and dev checkouts where the
		// .module-version marker isn't written.
		try {
			local.bi = new modules.wheels.vendor.wheels.BuildInfo();
			local.v = local.bi.version();
			if (Len(local.v) && local.v != "0.0.0-dev") return local.v;
		} catch (any e) {
			// BuildInfo unreachable; fall through.
		}

		// Tier 3 — sentinel. Matches "*" against any wheelsVersion
		// constraint via the SemVer comparator (treated as a
		// permissive dev build).
		return "0.0.0-dev";
	}
}
