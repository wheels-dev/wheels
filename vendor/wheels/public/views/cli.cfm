<!--- CLI & GUI Uses this file to talk to wheels via JSON when in maintenance/testing/development mode --->
<cfscript>
setting showDebugOutput="no";
migrator = application.wheels.migrator;
try {
	local.cliCommand = StructKeyExists(request.wheels.params, "command") ? request.wheels.params.command : "";

	// ── Security gate (2026-06-09 review SEC-4) ─────────────────────────
	// State-changing commands must arrive as POST from loopback carrying
	// the reload password — a plain GET here was CSRF-reachable (an <img>
	// tag on any page a developer visits could drop every table via
	// dbReset). Read-only commands stay on GET for the CLI and legacy GUI.
	local.writesMigrationFiles = StructKeyExists(request.wheels.params, "write") && request.wheels.params.write == "true";
	if (Len(local.cliCommand) && $cliCommandIsMutating(local.cliCommand, local.writesMigrationFiles)) {
		local.gate = $cliMutationGateCheck(
			requestMethod = cgi.request_method,
			remoteAddr = cgi.remote_addr,
			forwardedFor = cgi.http_x_forwarded_for,
			// Form scope ONLY: request.wheels.params merges URL + form, so a
			// ?password=... query string would satisfy the gate while logging
			// the reload password in access logs / proxies — contradicting the
			// SEC-4 design of carrying it as a form field (#2947 review, #2977).
			password = StructKeyExists(form, "password") ? form.password : ""
		);
		if (!local.gate.allowed) {
			cfheader(statuscode = local.gate.statusCode);
			cfcontent(type = "application/json");
			WriteOutput(
				SerializeJSON({
					"success" = false,
					"command" = local.cliCommand,
					"message" = local.gate.error,
					"messages" = local.gate.error
				})
			);
			abort;
		}
	}

	// ── Lazy migration discovery (2026-06-09 review P10) ────────────────
	// getAvailableMigrations() instantiates every migration CFC (a $dbinfo
	// round-trip each) and $getDBType() costs another probe, so only the
	// commands that actually consume them pay — `routes`, `introspect`, and
	// the jobs* commands job workers poll every few seconds skip discovery
	// entirely. An empty command keeps the full legacy ping payload.
	local.needsMigrations = !Len(local.cliCommand)
		|| ListFindNoCase("info,migrateUp,migrateDown,redoMigration,dbStatus,dbRollback", local.cliCommand) > 0;
	local.needsVersion = local.needsMigrations || CompareNoCase(local.cliCommand, "dbVersion") == 0;
	local.needsDbType = !Len(local.cliCommand)
		|| ListFindNoCase("info,doctor,dbSchema,dbCreate,dbReset,dbDump,dbRestore,dbShell", local.cliCommand) > 0;

	"data" = {};
	data["success"] = true;
	data["datasource"] = application.wheels.dataSourceName;
	data["wheelsVersion"] = application.wheels.version;
	data["currentVersion"] = local.needsVersion ? migrator.getCurrentMigrationVersion() : "";
	data["databaseType"] = local.needsDbType ? $cliDatabaseType() : "";
	data["migrations"] = local.needsMigrations ? migrator.getAvailableMigrations() : [];
	data["lastVersion"] = 0;
	data["message"] = "";
	data["messages"] = "";
	data["command"] = "";

	if (ArrayLen(data.migrations)) {
		data.lastVersion = data.migrations[ArrayLen(data.migrations)].version;
	}

	if (Len(local.cliCommand)) {
		data.command = local.cliCommand;

		// Dispatch to the CliBridge service (issue #2959). The 44-case switch
		// that used to live here is now one allowlist-gated method per command
		// in wheels.public.CliBridge — individually unit-testable, and the
		// dispatcher never spreads query-string keys into function arguments.
		// `context` carries the preamble-computed envelope values plus a `host`
		// reference (this Public instance) so handlers can reach framework
		// primitives (model(), get(), $cliFormatMigrationStatus(),
		// $cliResolveDumpPath()). An unrecognized command stays a silent no-op,
		// preserving the legacy default-less switch behavior.
		local.bridge = $cliBridge();
		if (local.bridge.handles(local.cliCommand)) {
			local.cliContext = {
				host = this,
				migrator = migrator,
				datasource = data.datasource,
				databaseType = data.databaseType,
				currentVersion = data.currentVersion,
				lastVersion = data.lastVersion,
				migrations = data.migrations
			};
			local.cliResult = local.bridge.dispatch(
				command = local.cliCommand,
				context = local.cliContext,
				params = request.wheels.params
			);
			StructAppend(data, local.cliResult, true);
		}
	}
} catch (any e) {
	data.success = false;
	// Envelope consistency: per-command catches surface their failure via
	// `data.message` (singular); the outer catch historically only set
	// `data.messages` (plural), so a CLI client reading either name in
	// isolation missed half the failure modes (issue ##2959). Mirror the
	// error on both keys so the plural stays backward-compatible while
	// the singular matches every other code path.
	data.message = e.message & ': ' & e.detail;
	data.messages = data.message;
}
</cfscript>
<cfcontent reset="true" type="application/json"><cfoutput>#SerializeJSON(data)#</cfoutput>
<cfabort>
