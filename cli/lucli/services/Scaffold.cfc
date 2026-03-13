/**
 * Scaffold service for generating complete CRUD resources.
 *
 * Orchestrates model + controller + views + migration + tests + routes
 * using CodeGen and Templates services. Supports rollback on failure.
 *
 * Ported from cli/src/models/ScaffoldService.cfc — no WireBox dependencies.
 */
component {

	public function init(
		required any codeGenService,
		required any helpers,
		required string projectRoot
	) {
		variables.codeGenService = arguments.codeGenService;
		variables.helpers = arguments.helpers;
		variables.projectRoot = arguments.projectRoot;
		return this;
	}

	/**
	 * Generate a complete scaffold (model, controller, views, migration, tests, routes)
	 */
	public struct function generateScaffold(
		required string name,
		required array properties,
		string belongsTo = "",
		string hasMany = "",
		boolean api = false,
		boolean tests = true,
		boolean force = false
	) {
		var results = {success: true, generated: [], errors: [], rollback: []};
		var pluralName = pluralName;

		try {
			// Add foreign key columns for belongsTo relationships
			var props = duplicate(arguments.properties);
			if (len(arguments.belongsTo)) {
				for (var parent in listToArray(arguments.belongsTo)) {
					var fkName = lCase(parent) & "Id";
					var hasFK = false;
					for (var p in props) {
						if (p.name == fkName) { hasFK = true; break; }
					}
					if (!hasFK) {
						arrayAppend(props, {name: fkName, type: "integer"});
					}
				}
			}

			// 1. Generate Model
			var modelResult = variables.codeGenService.generateModel(
				name = arguments.name,
				properties = props,
				belongsTo = arguments.belongsTo,
				hasMany = arguments.hasMany,
				force = arguments.force
			);
			if (modelResult.success) {
				arrayAppend(results.generated, {type: "model", path: modelResult.path});
				arrayAppend(results.rollback, modelResult.path);
			} else {
				throw(type="ScaffoldError", message="Model: #modelResult.error#");
			}

			// 2. Generate Migration
			var migrationPath = createMigrationWithProperties(arguments.name, props);
			arrayAppend(results.generated, {type: "migration", path: migrationPath});
			arrayAppend(results.rollback, migrationPath);

			// 3. Generate Controller
			var controllerResult = variables.codeGenService.generateController(
				name = pluralName,
				crud = true,
				api = arguments.api,
				force = arguments.force,
				belongsTo = arguments.belongsTo,
				hasMany = arguments.hasMany
			);
			if (controllerResult.success) {
				arrayAppend(results.generated, {type: "controller", path: controllerResult.path});
				arrayAppend(results.rollback, controllerResult.path);
			} else {
				throw(type="ScaffoldError", message="Controller: #controllerResult.error#");
			}

			// 4. Generate Views (unless API-only)
			if (!arguments.api) {
				for (var action in ["index", "show", "new", "edit", "_form"]) {
					var viewResult = variables.codeGenService.generateView(
						name = pluralName,
						action = action,
						force = arguments.force,
						properties = props,
						belongsTo = arguments.belongsTo,
						hasMany = arguments.hasMany
					);
					if (viewResult.success) {
						arrayAppend(results.generated, {type: "view", path: viewResult.path});
						arrayAppend(results.rollback, viewResult.path);
					}
				}
			}

			// 5. Generate Tests
			if (arguments.tests) {
				var modelTestResult = variables.codeGenService.generateTest(type = "model", name = arguments.name);
				if (modelTestResult.success) {
					arrayAppend(results.generated, {type: "test", path: modelTestResult.path});
					arrayAppend(results.rollback, modelTestResult.path);
				}

				var ctrlTestResult = variables.codeGenService.generateTest(type = "controller", name = pluralName);
				if (ctrlTestResult.success) {
					arrayAppend(results.generated, {type: "test", path: ctrlTestResult.path});
					arrayAppend(results.rollback, ctrlTestResult.path);
				}
			}

			// 6. Update routes
			updateRoutes(arguments.name);

		} catch (any e) {
			results.success = false;
			arrayAppend(results.errors, e.message);
			if (e.type == "ScaffoldError") {
				rollbackScaffold(results.rollback);
			}
		}

		return results;
	}

	/**
	 * Create a migration with properties for a table
	 */
	public string function createMigrationWithProperties(
		required string name,
		required array properties,
		string primaryKey = "id"
	) {
		var timestamp = variables.helpers.generateMigrationTimestamp();
		var tableName = variables.helpers.pluralize(lCase(arguments.name));
		var className = "create_#tableName#_table";
		var fileName = timestamp & "_" & className & ".cfc";
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";

		if (!directoryExists(migrationDir)) {
			directoryCreate(migrationDir, true);
		}

		var content = generateMigrationContent(className, tableName, arguments.properties, arguments.primaryKey);
		var migrationPath = migrationDir & "/" & fileName;
		fileWrite(migrationPath, content);

		return migrationPath;
	}

	/**
	 * Update routes.cfm with a new resource route
	 */
	public boolean function updateRoutes(required string name) {
		try {
			var routesPath = variables.projectRoot & "/config/routes.cfm";
			if (!fileExists(routesPath)) return false;

			var content = fileRead(routesPath);
			var resourceName = lCase(pluralName);
			var resourceRoute = '.resources("' & resourceName & '")';

			// Skip if route already exists
			if (findNoCase(resourceRoute, content)) return false;

			// Try CLI-Appends-Here marker first
			var markerPattern = '// CLI-Appends-Here';
			var indent = '';

			if (find(chr(9) & chr(9) & chr(9) & markerPattern, content)) {
				indent = chr(9) & chr(9) & chr(9);
			} else if (find(chr(9) & chr(9) & markerPattern, content)) {
				indent = chr(9) & chr(9);
			} else if (find(chr(9) & markerPattern, content)) {
				indent = chr(9);
			}

			var fullMarker = indent & markerPattern;
			if (find(fullMarker, content)) {
				content = replace(content, fullMarker, indent & resourceRoute & chr(10) & fullMarker, 'all');
				fileWrite(routesPath, content);
				return true;
			}

			// Fallback: insert before last .end()
			if (find('.end()', content)) {
				var lastEnd = content.lastIndexOf('.end()');
				if (lastEnd >= 0) {
					content = mid(content, 1, lastEnd) & resourceRoute & chr(10) & chr(9) & mid(content, lastEnd + 1, len(content));
					fileWrite(routesPath, content);
					return true;
				}
			}
		} catch (any e) {
			// Routes update is non-critical
		}
		return false;
	}

	// ── Private helpers ──────────────────────────────

	/**
	 * Generate migration content with column definitions
	 */
	private string function generateMigrationContent(
		required string className,
		required string tableName,
		required array properties,
		string primaryKey = "id"
	) {
		var nl = chr(10);
		var t = chr(9);
		var c = "";

		c &= 'component extends="wheels.migrator.Migration" hint="Migration: #arguments.className#" {' & nl & nl;
		c &= t & 'function up() {' & nl;
		c &= t & t & 'transaction {' & nl;
		c &= t & t & t & 'try {' & nl;
		c &= t & t & t & t & "t = createTable(name='#arguments.tableName#', force='false', id='true', primaryKey='#arguments.primaryKey#');" & nl;

		for (var prop in arguments.properties) {
			if (structKeyExists(prop, "association")) continue;
			if (!structKeyExists(prop, "type")) continue;

			var cfType = mapToCFWheelsType(prop.type);
			var params = "columnNames='#prop.name#'";
			params &= ", default=''";
			params &= ", allowNull=" & (structKeyExists(prop, "required") && prop.required ? "false" : "true");

			switch (cfType) {
				case "string": params &= ", limit='255'"; break;
				case "decimal": params &= ", precision='10', scale='2'"; break;
				case "integer": params &= ", limit='11'"; break;
			}

			c &= t & t & t & t & "t.#cfType#(#params#);" & nl;
		}

		c &= t & t & t & t & "t.timestamps();" & nl;
		c &= t & t & t & t & "t.create();" & nl;
		c &= t & t & t & '} catch (any e) {' & nl;
		c &= t & t & t & t & 'local.exception = e;' & nl;
		c &= t & t & t & '}' & nl & nl;
		c &= t & t & t & 'if (StructKeyExists(local, "exception")) {' & nl;
		c &= t & t & t & t & 'transaction action="rollback";' & nl;
		c &= t & t & t & t & 'Throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");' & nl;
		c &= t & t & t & '} else {' & nl;
		c &= t & t & t & t & 'transaction action="commit";' & nl;
		c &= t & t & t & '}' & nl;
		c &= t & t & '}' & nl;
		c &= t & '}' & nl & nl;

		c &= t & 'function down() {' & nl;
		c &= t & t & 'transaction {' & nl;
		c &= t & t & t & 'try {' & nl;
		c &= t & t & t & t & "dropTable('#arguments.tableName#');" & nl;
		c &= t & t & t & '} catch (any e) {' & nl;
		c &= t & t & t & t & 'local.exception = e;' & nl;
		c &= t & t & t & '}' & nl & nl;
		c &= t & t & t & 'if (StructKeyExists(local, "exception")) {' & nl;
		c &= t & t & t & t & 'transaction action="rollback";' & nl;
		c &= t & t & t & t & 'Throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");' & nl;
		c &= t & t & t & '} else {' & nl;
		c &= t & t & t & t & 'transaction action="commit";' & nl;
		c &= t & t & t & '}' & nl;
		c &= t & t & '}' & nl;
		c &= t & '}' & nl & nl;

		c &= '}' & nl;
		return c;
	}

	/**
	 * Map property type to CFWheels migration column type
	 */
	private string function mapToCFWheelsType(required string type) {
		switch (lCase(arguments.type)) {
			case "string": return "string";
			case "text": return "text";
			case "integer": case "int": return "integer";
			case "biginteger": case "bigint": return "biginteger";
			case "float": case "double": return "float";
			case "decimal": case "numeric": return "decimal";
			case "boolean": case "bool": return "boolean";
			case "date": return "date";
			case "datetime": case "timestamp": return "datetime";
			case "time": return "time";
			case "binary": case "blob": return "binary";
			case "uuid": return "uniqueidentifier";
			default: return "string";
		}
	}

	/**
	 * Rollback created files on error
	 */
	private void function rollbackScaffold(required array files) {
		for (var file in arguments.files) {
			if (fileExists(file)) {
				try { fileDelete(file); } catch (any e) { /* non-critical */ }
			}
		}
	}

}
