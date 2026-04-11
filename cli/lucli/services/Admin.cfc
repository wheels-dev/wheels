/**
 * Admin CRUD generation service.
 *
 * Introspects a model via the running Wheels server to get column types
 * and associations, then generates an admin-scoped controller and views.
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
	 * Generate admin CRUD for a model using server introspection data.
	 */
	public struct function generateAdmin(
		required struct modelData,
		boolean force = false,
		boolean noRoutes = false
	) {
		var result = {success: true, generated: [], errors: []};
		var singular = lCase(arguments.modelData.model);
		var plural = variables.helpers.pluralize(singular);
		var singularCap = variables.helpers.capitalize(singular);
		var pluralCap = variables.helpers.capitalize(plural);

		// Filter out non-form columns
		var formColumns = [];
		var allColumns = [];
		for (var col in arguments.modelData.columns) {
			arrayAppend(allColumns, col);
			if (col.primaryKey ?: false) continue;
			if (listFindNoCase("createdAt,updatedAt,deletedAt", col.name)) continue;
			arrayAppend(formColumns, col);
		}

		// Build template context
		var context = {
			singular: singular,
			plural: plural,
			SingularCap: singularCap,
			PluralCap: pluralCap,
			primaryKey: arguments.modelData.primaryKey ?: "id"
		};

		// Build dynamic template sections
		context.beforeFilters = buildBeforeFilters(arguments.modelData.associations);
		context.foreignKeyLoaders = buildForeignKeyLoaders(arguments.modelData.associations);
		context.indexHeaders = buildIndexHeaders(formColumns);
		context.indexCells = buildIndexCells(formColumns, plural);
		context.showFields = buildShowFields(allColumns, singular);
		context.formFields = buildFormFields(formColumns, singular);

		// Generate controller
		var controllerDir = variables.projectRoot & "/app/controllers/admin";
		if (!directoryExists(controllerDir)) directoryCreate(controllerDir, true);
		var controllerPath = controllerDir & "/" & pluralCap & ".cfc";
		if (fileExists(controllerPath) && !arguments.force) {
			arrayAppend(result.errors, "Controller already exists: app/controllers/admin/#pluralCap#.cfc (use --force to overwrite)");
			result.success = false;
			return result;
		}
		var controllerTemplate = fileRead(variables.moduleRoot & "templates/admin/controller.txt");
		fileWrite(controllerPath, processTemplate(controllerTemplate, context));
		arrayAppend(result.generated, "app/controllers/admin/#pluralCap#.cfc");

		// Generate views
		var viewDir = variables.projectRoot & "/app/views/admin/" & plural;
		if (!directoryExists(viewDir)) directoryCreate(viewDir, true);

		var viewTemplates = ["index", "show", "new", "edit", "_form"];
		for (var viewName in viewTemplates) {
			var viewPath = viewDir & "/" & viewName & ".cfm";
			if (fileExists(viewPath) && !arguments.force) {
				arrayAppend(result.errors, "View already exists: app/views/admin/#plural#/#viewName#.cfm");
				continue;
			}
			var viewTemplate = fileRead(variables.moduleRoot & "templates/admin/" & viewName & ".txt");
			fileWrite(viewPath, processTemplate(viewTemplate, context));
			arrayAppend(result.generated, "app/views/admin/#plural#/#viewName#.cfm");
		}

		// Inject routes
		if (!arguments.noRoutes) {
			var routeResult = injectAdminRoute(plural);
			if (routeResult) {
				arrayAppend(result.generated, "Route: admin scope -> .resources(""#plural#"")");
			}
		}

		return result;
	}

	// ── Template builders ──────────────────────────────────────

	private string function buildBeforeFilters(required array associations) {
		var filters = "";
		var nl = chr(10);
		var t = chr(9);
		for (var assoc in arguments.associations) {
			if ((assoc.type ?: "") == "belongsTo") {
				var loaderName = "load" & variables.helpers.capitalize(variables.helpers.pluralize(assoc.name));
				filters &= t & t & 'filters(through="#loaderName#", only="new,edit,create,update");' & nl;
			}
		}
		return filters;
	}

	private string function buildForeignKeyLoaders(required array associations) {
		var loaders = "";
		var nl = chr(10);
		var t = chr(9);
		for (var assoc in arguments.associations) {
			if ((assoc.type ?: "") == "belongsTo") {
				var modelName = assoc.modelName ?: variables.helpers.capitalize(assoc.name);
				var pluralName = variables.helpers.pluralize(lCase(assoc.name));
				var loaderName = "load" & variables.helpers.capitalize(pluralName);
				loaders &= t & "private function #loaderName#() {" & nl;
				loaders &= t & t & '#pluralName# = model("#modelName#").findAll(order="id");' & nl;
				loaders &= t & "}" & nl & nl;
			}
		}
		return loaders;
	}

	private string function buildIndexHeaders(required array columns) {
		var headers = "";
		var nl = chr(10);
		var t = chr(9);
		for (var col in arguments.columns) {
			headers &= t & t & t & "<th>#variables.helpers.capitalize(col.name)#</th>" & nl;
		}
		return headers;
	}

	private string function buildIndexCells(required array columns, required string plural) {
		var cells = "";
		var nl = chr(10);
		var t = chr(9);
		for (var col in arguments.columns) {
			cells &= t & t & t & "<td>###arguments.plural#.#col.name###</td>" & nl;
		}
		return cells;
	}

	private string function buildShowFields(required array columns, required string singular) {
		var fields = "";
		var nl = chr(10);
		var t = chr(9);
		for (var col in arguments.columns) {
			fields &= t & "<dt>#variables.helpers.capitalize(col.name)#</dt>" & nl;
			fields &= t & "<dd>###arguments.singular#.#col.name###</dd>" & nl;
		}
		return fields;
	}

	private string function buildFormFields(required array columns, required string singular) {
		var fields = "";
		var nl = chr(10);
		var t = chr(9);
		for (var col in arguments.columns) {
			var helper = mapColumnToFormHelper(col);
			fields &= t & "<div>" & nl;
			fields &= t & t & '##' & helper & '(objectName="#arguments.singular#", property="#col.name#")##' & nl;
			fields &= t & "</div>" & nl;
		}
		return fields;
	}

	private string function mapColumnToFormHelper(required struct col) {
		var colType = lCase(col.type ?: "string");
		var colName = lCase(col.name);

		// Name-based conventions
		if (findNoCase("email", colName)) return "emailField";
		if (colName == "url" || colName == "website") return "urlField";
		if (findNoCase("phone", colName) || findNoCase("tel", colName)) return "telField";

		// Type-based mapping
		switch (colType) {
			case "text": case "clob": case "longtext":
				return "textArea";
			case "boolean": case "bit": case "cf_sql_bit":
				return "checkBox";
			case "integer": case "int": case "bigint": case "smallint": case "numeric":
				return "numberField";
			case "decimal": case "float": case "double": case "money":
				return "numberField";
			case "date":
				return "dateField";
			case "datetime": case "timestamp":
				return "dateTimeLocalField";
			default:
				return "textField";
		}
	}

	// ── Route injection ──────────────────────────────────────

	private boolean function injectAdminRoute(required string plural) {
		var routesPath = variables.projectRoot & "/config/routes.cfm";
		if (!fileExists(routesPath)) return false;

		var content = fileRead(routesPath);
		var nl = chr(10);
		var t = chr(9);
		var resourceLine = '.resources("' & arguments.plural & '")';

		// Check if this admin resource already exists
		if (findNoCase('scope(path="admin"', content) && findNoCase(resourceLine, content)) {
			return false;
		}

		// Try to find existing admin scope and append inside it
		if (reFindNoCase('\.scope\(\s*path\s*=\s*"admin"', content)) {
			// Find the admin scope opening and insert the resource before its .end()
			var adminScopePos = reFindNoCase('\.scope\(\s*path\s*=\s*"admin"[^)]*\)', content);
			if (adminScopePos > 0) {
				// Find the .end() that closes this scope — simple heuristic: first .end() after scope
				var afterScope = mid(content, adminScopePos, len(content));
				var endPos = findNoCase(".end()", afterScope);
				if (endPos > 0) {
					var insertAt = adminScopePos + endPos - 2;
					content = left(content, insertAt) & t & t & resourceLine & nl & t & mid(content, insertAt + 1, len(content));
					fileWrite(routesPath, content);
					return true;
				}
			}
		}

		// No existing admin scope — create one before CLI-Appends-Here or last .end()
		var marker = "// CLI-Appends-Here";
		var adminBlock = t & '.scope(path="admin", package="admin")' & nl;
		adminBlock &= t & t & resourceLine & nl;
		adminBlock &= t & ".end()" & nl & t;

		if (find(marker, content)) {
			content = replace(content, marker, adminBlock & marker);
		} else if (find(".end()", content)) {
			var lastEnd = content.lastIndexOf(".end()");
			if (lastEnd >= 0) {
				content = left(content, lastEnd) & adminBlock & mid(content, lastEnd + 1, len(content));
			}
		}

		fileWrite(routesPath, content);
		return true;
	}

	private string function processTemplate(required string template, required struct context) {
		var result = arguments.template;
		for (var key in arguments.context) {
			result = replaceNoCase(result, "{{#key#}}", arguments.context[key], "all");
		}
		return result;
	}

}
