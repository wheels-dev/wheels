/**
 * In-process migration runner for Wheels applications.
 *
 * Designed to be invoked by LuCLI's LuceeScriptEngine for Phase 4
 * in-process command execution. Falls back to HTTP when a server is running.
 *
 * Usage from LuceeScriptEngine:
 *   var runner = new modules.wheels.services.MigrationRunner(projectRoot);
 *   var result = runner.latest();
 */
component {

	function init(required string projectRoot) {
		variables.projectRoot = arguments.projectRoot;
		return this;
	}

	/**
	 * Run migrations to latest version (in-process).
	 * Requires application.wheels.migrator to be initialized.
	 */
	public struct function latest() {
		return executeMigration("migrateToLatest");
	}

	/**
	 * Run one migration up (in-process).
	 */
	public struct function up() {
		return executeMigration("migrateUp");
	}

	/**
	 * Roll back one migration (in-process).
	 */
	public struct function down() {
		return executeMigration("migrateDown");
	}

	/**
	 * Get migration status info (in-process).
	 */
	public struct function info() {
		ensureContext();
		var migrator = application.wheels.migrator;
		var migrations = migrator.getAvailableMigrations();
		var currentVersion = migrator.getCurrentMigrationVersion();

		var result = {
			success: true,
			currentVersion: currentVersion,
			migrations: [],
			summary: { total: 0, applied: 0, pending: 0 }
		};

		for (var m in migrations) {
			var status = m.version <= currentVersion ? "applied" : "pending";
			arrayAppend(result.migrations, {
				version: m.version,
				description: m.name,
				status: status
			});
			if (status == "applied") result.summary.applied++;
			else result.summary.pending++;
		}
		result.summary.total = arrayLen(result.migrations);

		return result;
	}

	/**
	 * Migrate to a specific version (in-process).
	 */
	public struct function migrateTo(required string version) {
		ensureContext();
		var migrator = application.wheels.migrator;

		try {
			var message = migrator.migrateTo(arguments.version);
			return { success: true, message: message };
		} catch (any e) {
			return { success: false, message: e.message, detail: e.detail ?: "" };
		}
	}

	/**
	 * Run via HTTP to a running server (Phase 2-3 fallback).
	 */
	public struct function runViaHttp(required numeric serverPort, required string action) {
		var command = "";
		switch (action) {
			case "latest": command = "migrateTo"; break;
			case "up":     command = "migrateUp"; break;
			case "down":   command = "migrateDown"; break;
			case "info":   command = "info"; break;
			default:       command = action;
		}

		var url = "http://localhost:#serverPort#/wheels/cli?command=#command#&format=json";
		var httpService = new http(url=url, method="GET", timeout=120);
		var httpResult = httpService.send().getPrefix();

		if (httpResult.statusCode contains "200" && isJSON(httpResult.fileContent)) {
			return deserializeJSON(httpResult.fileContent);
		}

		return { success: false, message: "HTTP #httpResult.statusCode#" };
	}

	// ── Private ─────────────────────────────────────

	private struct function executeMigration(required string method) {
		ensureContext();
		var migrator = application.wheels.migrator;

		try {
			var message = invoke(migrator, arguments.method);
			return { success: true, message: message ?: "Migration completed." };
		} catch (any e) {
			return { success: false, message: e.message, detail: e.detail ?: "" };
		}
	}

	private void function ensureContext() {
		if (!structKeyExists(application, "wheels") || !structKeyExists(application.wheels, "migrator")) {
			throw(
				type="Wheels.MigrationRunner.NoContext",
				message="Wheels application context not initialized. Run wheels server start or load the app context first."
			);
		}
	}

}
