/**
 * Service for destroying (removing) generated Wheels components.
 *
 * Handles file deletion, route cleanup, and migration generation
 * for resource, model, controller, and view destruction.
 */
component {

	public function init(
		required any helpers,
		required string projectRoot,
		required string moduleRoot
	) {
		variables.helpers = arguments.helpers;
		variables.projectRoot = arguments.projectRoot;
		variables.moduleRoot = arguments.moduleRoot;
		return this;
	}

	/**
	 * Destroy a complete resource (model + controller + views + tests + route + migration)
	 */
	public struct function destroyResource(required string name) {
		var result = {success: true, deleted: [], warnings: [], migrationPath: ""};
		var names = getNameVariants(arguments.name);

		// Model
		deleteFileIfExists(
			variables.projectRoot & "/app/models/" & names.singularCap & ".cfc",
			result
		);

		// Controller
		deleteFileIfExists(
			variables.projectRoot & "/app/controllers/" & names.pluralCap & ".cfc",
			result
		);

		// Views directory
		deleteDirIfExists(
			variables.projectRoot & "/app/views/" & names.plural,
			result
		);

		// Model test
		deleteFileIfExists(
			variables.projectRoot & "/tests/specs/models/" & names.singularCap & "Spec.cfc",
			result
		);

		// Controller test
		deleteFileIfExists(
			variables.projectRoot & "/tests/specs/controllers/" & names.pluralCap & "Spec.cfc",
			result
		);

		// View tests directory
		deleteDirIfExists(
			variables.projectRoot & "/tests/specs/views/" & names.plural,
			result
		);

		// Route cleanup
		removeRoute(names.plural, result);

		// Generate drop-table migration
		result.migrationPath = generateRemoveTableMigration(names.plural);

		return result;
	}

	/**
	 * Destroy a model and its test, generate drop-table migration
	 */
	public struct function destroyModel(required string name) {
		var result = {success: true, deleted: [], warnings: [], migrationPath: ""};
		var names = getNameVariants(arguments.name);

		deleteFileIfExists(
			variables.projectRoot & "/app/models/" & names.singularCap & ".cfc",
			result
		);
		deleteFileIfExists(
			variables.projectRoot & "/tests/specs/models/" & names.singularCap & "Spec.cfc",
			result
		);

		result.migrationPath = generateRemoveTableMigration(names.plural);

		return result;
	}

	/**
	 * Destroy a controller and its test
	 */
	public struct function destroyController(required string name) {
		var result = {success: true, deleted: [], warnings: []};
		var names = getNameVariants(arguments.name);

		deleteFileIfExists(
			variables.projectRoot & "/app/controllers/" & names.pluralCap & ".cfc",
			result
		);
		deleteFileIfExists(
			variables.projectRoot & "/tests/specs/controllers/" & names.pluralCap & "Spec.cfc",
			result
		);

		return result;
	}

	/**
	 * Destroy views — either a whole directory or a single file
	 * If name contains "/", treat as controller/view (single file).
	 * Otherwise, delete the entire views directory + test directory.
	 */
	public struct function destroyView(required string name) {
		var result = {success: true, deleted: [], warnings: []};

		if (find("/", arguments.name)) {
			// Single view file: "products/index"
			var parts = listToArray(arguments.name, "/");
			if (arrayLen(parts) != 2 || !len(parts[1]) || !len(parts[2])) {
				result.success = false;
				result.warnings = ["Invalid view path. Use: controller/viewname (e.g., products/index)"];
				return result;
			}
			var viewPath = variables.projectRoot & "/app/views/" & parts[1] & "/" & parts[2] & ".cfm";
			deleteFileIfExists(viewPath, result);
		} else {
			// Entire view directory
			var names = getNameVariants(arguments.name);
			deleteDirIfExists(
				variables.projectRoot & "/app/views/" & names.plural,
				result
			);
			deleteDirIfExists(
				variables.projectRoot & "/tests/specs/views/" & names.plural,
				result
			);
		}

		return result;
	}

	/**
	 * Build the list of files/dirs that would be deleted (for confirmation display)
	 */
	public array function previewDestroy(required string name, required string type) {
		var preview = [];
		var names = getNameVariants(arguments.name);

		switch (arguments.type) {
			case "resource":
				arrayAppend(preview, "app/models/" & names.singularCap & ".cfc");
				arrayAppend(preview, "app/controllers/" & names.pluralCap & ".cfc");
				arrayAppend(preview, "app/views/" & names.plural & "/");
				arrayAppend(preview, "tests/specs/models/" & names.singularCap & "Spec.cfc");
				arrayAppend(preview, "tests/specs/controllers/" & names.pluralCap & "Spec.cfc");
				arrayAppend(preview, "tests/specs/views/" & names.plural & "/");
				arrayAppend(preview, 'Route: .resources("' & names.plural & '") from config/routes.cfm');
				arrayAppend(preview, "Migration: drop table " & names.plural);
				break;
			case "model":
				arrayAppend(preview, "app/models/" & names.singularCap & ".cfc");
				arrayAppend(preview, "tests/specs/models/" & names.singularCap & "Spec.cfc");
				arrayAppend(preview, "Migration: drop table " & names.plural);
				break;
			case "controller":
				arrayAppend(preview, "app/controllers/" & names.pluralCap & ".cfc");
				arrayAppend(preview, "tests/specs/controllers/" & names.pluralCap & "Spec.cfc");
				break;
			case "view":
				if (find("/", arguments.name)) {
					var parts = listToArray(arguments.name, "/");
					arrayAppend(preview, "app/views/" & parts[1] & "/" & parts[2] & ".cfm");
				} else {
					arrayAppend(preview, "app/views/" & names.plural & "/");
					arrayAppend(preview, "tests/specs/views/" & names.plural & "/");
				}
				break;
		}

		return preview;
	}

	// ── Private helpers ──────────────────────────────────────

	private struct function getNameVariants(required string name) {
		var clean = variables.helpers.stripSpecialChars(trim(arguments.name));
		var singular = variables.helpers.singularize(lCase(clean));
		var plural = variables.helpers.pluralize(lCase(clean));
		return {
			singular: singular,
			plural: plural,
			singularCap: variables.helpers.capitalize(singular),
			pluralCap: variables.helpers.capitalize(plural)
		};
	}

	private void function deleteFileIfExists(required string path, required struct result) {
		if (fileExists(arguments.path)) {
			fileDelete(arguments.path);
			arrayAppend(arguments.result.deleted, arguments.path);
		} else {
			arrayAppend(arguments.result.warnings, "Not found: " & arguments.path);
		}
	}

	private void function deleteDirIfExists(required string path, required struct result) {
		if (directoryExists(arguments.path)) {
			directoryDelete(arguments.path, true);
			arrayAppend(arguments.result.deleted, arguments.path & "/");
		} else {
			arrayAppend(arguments.result.warnings, "Not found: " & arguments.path & "/");
		}
	}

	private void function removeRoute(required string pluralName, required struct result) {
		var routesPath = variables.projectRoot & "/config/routes.cfm";
		if (!fileExists(routesPath)) {
			arrayAppend(arguments.result.warnings, "config/routes.cfm not found");
			return;
		}

		var content = fileRead(routesPath);
		var nl = chr(10);
		var pattern = '.resources("' & arguments.pluralName & '")';

		if (!findNoCase(pattern, content)) {
			arrayAppend(arguments.result.warnings, "Route not found: " & pattern);
			return;
		}

		// Remove the line containing the resource route
		var lines = listToArray(content, nl, true);
		var filtered = [];
		for (var line in lines) {
			if (!findNoCase(pattern, line)) {
				arrayAppend(filtered, line);
			}
		}
		fileWrite(routesPath, arrayToList(filtered, nl));
		arrayAppend(arguments.result.deleted, "Route: " & pattern);
	}

	private string function generateRemoveTableMigration(required string tableName) {
		var timestamp = variables.helpers.generateMigrationTimestamp();
		var className = "remove_" & arguments.tableName & "_table";
		var fileName = timestamp & "_" & className & ".cfc";
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";

		if (!directoryExists(migrationDir)) {
			directoryCreate(migrationDir, true);
		}

		// Read template and substitute
		var templatePath = variables.moduleRoot & "templates/migrations/remove_table.txt";
		var content = fileRead(templatePath);
		content = replaceNoCase(content, "{{className}}", className, "all");
		content = replaceNoCase(content, "{{tableName}}", arguments.tableName, "all");

		var migrationPath = migrationDir & "/" & fileName;
		fileWrite(migrationPath, content);
		return migrationPath;
	}

}
