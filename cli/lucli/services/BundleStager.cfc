/**
 * Datasource-bundle staging helpers for `wheels start`.
 *
 * Lucee 7's stock Express distribution ships JDBC drivers for MySQL, MSSQL,
 * PostgreSQL, and HSQLDB but not SQLite — yet `wheels new` writes SQLite as
 * the zero-config default datasource. Without a JAR somewhere Lucee can find
 * (Tomcat classpath via lib/ext/, or an OSGi bundle), every fresh app fails
 * on first request with `ClassException: org.sqlite.JDBC`. See GH #2326 (F8).
 *
 * Isolated from Module.cfc so tests can exercise the behavior without
 * instantiating the full LuCLI module (which depends on a `modules.BaseModule`
 * mapping that only exists when LuCLI is hosting the runtime).
 */
component {

	public function init() {
		return this;
	}

	/**
	 * True if the project's `config/app.cfm` declares any kind of SQLite
	 * datasource. Detection covers both the legacy app.cfm format that
	 * carried `bundleName: "org.xerial.sqlite-jdbc"` and the current format
	 * (post-#2304) that omits the bundleName hint and relies on classpath
	 * resolution of `org.sqlite.JDBC`.
	 *
	 * @projectRoot Absolute path to the project root (where config/app.cfm
	 *              lives). Empty / missing path → returns false.
	 */
	public boolean function projectUsesSqliteDatasource(required string projectRoot) {
		if (!len(arguments.projectRoot)) return false;
		var appCfm = arguments.projectRoot & "/config/app.cfm";
		if (!fileExists(appCfm)) return false;
		var content = fileRead(appCfm);
		return findNoCase("jdbc:sqlite:", content) > 0
			|| findNoCase("org.sqlite.JDBC", content) > 0
			|| findNoCase("org.xerial.sqlite-jdbc", content) > 0;
	}

	/**
	 * Copy the given JAR into every Lucee Express install's `lib/ext/`
	 * directory beneath `expressRoot`. Idempotent — skips destinations that
	 * already have the JAR. Best-effort — silently swallows per-version
	 * copy failures so a permission issue on one Lucee version doesn't
	 * block staging for others.
	 *
	 * Returns a struct documenting what happened, useful for tests and
	 * future logging:
	 *   { staged: [list of dest paths written],
	 *     skipped: [list of dest paths that already existed],
	 *     failed:  [list of dest paths we couldn't write] }
	 *
	 * @bundleSrc   Absolute path to the source JAR (e.g. inside the
	 *              wheels-module distribution at
	 *              cli/lucli/resources/extensions/sqlite/<jar>.jar).
	 * @expressRoot Absolute path to LUCLI_HOME/express/ — staging looks at
	 *              every immediate child directory and treats it as a Lucee
	 *              version.
	 * @jarFileName Filename to use at the destination (typically the
	 *              upstream Maven artifact name, e.g.
	 *              `sqlite-jdbc-3.49.1.0.jar`, since Tomcat's classpath
	 *              loader doesn't care about OSGi symbolic-name renaming).
	 */
	public struct function stageIntoLibExt(
		required string bundleSrc,
		required string expressRoot,
		required string jarFileName
	) {
		var result = { staged: [], skipped: [], failed: [] };
		if (!fileExists(arguments.bundleSrc)) return result;
		if (!directoryExists(arguments.expressRoot)) return result;

		var versions = directoryList(arguments.expressRoot, false, "name");
		for (var v in versions) {
			var libExt = arguments.expressRoot & "/" & v & "/lib/ext";
			if (!directoryExists(libExt)) continue;
			var dest = libExt & "/" & arguments.jarFileName;
			if (fileExists(dest)) {
				arrayAppend(result.skipped, dest);
				continue;
			}
			try {
				fileCopy(arguments.bundleSrc, dest);
				arrayAppend(result.staged, dest);
			} catch (any e) {
				arrayAppend(result.failed, dest);
			}
		}
		return result;
	}

	/**
	 * Copy the given JAR into every per-server Lucee bundles directory
	 * beneath `serversRoot` (i.e. LUCLI_HOME/servers/<name>/lucee-server/bundles).
	 * Idempotent — skips destinations that already have the JAR. Best-effort —
	 * silently swallows per-server copy failures.
	 *
	 * Why this is necessary on top of `stageIntoLibExt`: Lucee 7's datasource
	 * subsystem resolves JDBC drivers through its OSGi bundle loader, not the
	 * Tomcat parent classloader. A JAR on the Tomcat `lib/ext/` classpath is
	 * visible to `Class.forName()` but not to Lucee's datasource resolver,
	 * which means SQLite-by-default apps fail at the first `cfquery` even when
	 * `lib/ext/` has the driver. Onboarding finding F2 documents this — every
	 * fresh `wheels migrate latest` against a SQLite app fails until the JAR
	 * lands in bundles/. MySQL and PostgreSQL avoid the issue because their
	 * bundles ship inside `lucee-7.x.x.jar` and Lucee auto-deploys them; the
	 * SQLite extension is third-party and doesn't get the same treatment.
	 *
	 * @bundleSrc   Absolute path to the source JAR (typically the OSGi-named
	 *              variant, e.g. `org.xerial.sqlite-jdbc-3.49.1.0.jar`, since
	 *              Lucee's bundle loader uses the symbolic name).
	 * @serversRoot Absolute path to LUCLI_HOME/servers/ — staging looks at
	 *              every immediate child directory and treats it as a server
	 *              context.
	 * @jarFileName Filename to use at the destination. Should match the OSGi
	 *              symbolic name + version (e.g. `org.xerial.sqlite-jdbc-3.49.1.0.jar`).
	 */
	public struct function stageIntoServerBundles(
		required string bundleSrc,
		required string serversRoot,
		required string jarFileName
	) {
		var result = { staged: [], skipped: [], failed: [] };
		if (!fileExists(arguments.bundleSrc)) return result;
		if (!directoryExists(arguments.serversRoot)) return result;

		var servers = directoryList(arguments.serversRoot, false, "name");
		for (var s in servers) {
			var bundlesDir = arguments.serversRoot & "/" & s & "/lucee-server/bundles";
			if (!directoryExists(bundlesDir)) continue;
			var dest = bundlesDir & "/" & arguments.jarFileName;
			if (fileExists(dest)) {
				arrayAppend(result.skipped, dest);
				continue;
			}
			try {
				fileCopy(arguments.bundleSrc, dest);
				arrayAppend(result.staged, dest);
			} catch (any e) {
				arrayAppend(result.failed, dest);
			}
		}
		return result;
	}

}
