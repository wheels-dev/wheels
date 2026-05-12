/**
 * Generate an admin CRUD interface for an existing model.
 *
 * Introspects the model to produce type-aware admin views (index, show, new, edit, _form),
 * an admin-namespaced controller with CSRF protection, and injects scoped routes.
 *
 * The model must already exist and be loadable by the running Wheels application.
 *
 * Examples:
 * wheels generate admin User
 * wheels generate admin Product --force
 * wheels generate admin Post --noRoutes
 */
component aliases="wheels g admin" extends="../base" {

	property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
	property name="adminViewService" inject="AdminViewService@wheels-cli";
	property name="adminIntrospectionService" inject="AdminIntrospectionService@wheels-cli";
	property name="templateService" inject="TemplateService@wheels-cli";
	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @name.hint Name of the model to generate admin for (singular, e.g. "User", "Product")
	 * @force.hint Overwrite existing files
	 * @noRoutes.hint Skip route injection into config/routes.cfm
	 */
	function run(
		required string name,
		boolean force = false,
		boolean noRoutes = false
	) {
		requireWheelsApp(getCWD());
		arguments = reconstructArgs(argStruct=arguments);

		// Validate model name
		var validation = codeGenerationService.validateName(arguments.name, "model");
		if (!validation.valid) {
			detailOutput.error("Invalid model name: " & arrayToList(validation.errors, ", "));
			return;
		}

		var modelName = Helpers.capitalize(arguments.name);
		var pluralName = Helpers.pluralize(modelName);
		var pluralLower = lCase(pluralName);
		var singularLower = lCase(modelName);

		detailOutput.header("Generating admin interface for: #modelName#");

		// ── 1. Introspect the model ──────────────────────
		var metadata = {};
		try {
			var modelInstance = application.wo.model(modelName);
			metadata = adminIntrospectionService.introspect(modelInstance);
		} catch (any e) {
			detailOutput.error("Could not introspect model '#modelName#'. Is the application running and the model valid?");
			detailOutput.error("Detail: #e.message#");
			setExitCode(1);
			return;
		}

		var filesCreated = 0;

		// ── 2. Generate admin controller ─────────────────
		var controllerResult = generateAdminController(
			modelName = modelName,
			metadata = metadata,
			force = arguments.force
		);

		if (controllerResult.success) {
			detailOutput.create(controllerResult.path);
			filesCreated++;
		} else {
			detailOutput.error("Controller: #controllerResult.error#");
			if (!arguments.force) {
				detailOutput.error("Use --force to overwrite existing files.");
				setExitCode(1);
				return;
			}
		}

		// ── 3. Generate admin views ──────────────────────
		// Index and Show views via AdminViewService (type-aware)
		var indexResult = adminViewService.generateIndexView(
			metadata = metadata,
			baseDirectory = getCWD()
		);
		if (indexResult.success) {
			detailOutput.create(indexResult.path);
			filesCreated++;
		} else {
			detailOutput.error("Index view: #indexResult.error#");
		}

		var showResult = adminViewService.generateShowView(
			metadata = metadata,
			baseDirectory = getCWD()
		);
		if (showResult.success) {
			detailOutput.create(showResult.path);
			filesCreated++;
		} else {
			detailOutput.error("Show view: #showResult.error#");
		}

		// New, Edit, _form views via CodeGenerationService (use admin templates)
		var formViews = ["new", "edit", "_form"];
		for (var viewAction in formViews) {
			var viewResult = codeGenerationService.generateView(
				name = "admin/#pluralName#",
				action = viewAction,
				force = arguments.force,
				baseDirectory = getCWD(),
				admin = true,
				adminFields = metadata.fields
			);
			if (viewResult.success) {
				detailOutput.create(viewResult.path);
				filesCreated++;
			} else {
				detailOutput.error("#viewAction# view: #viewResult.error#");
			}
		}

		// ── 4. Inject admin routes ───────────────────────
		if (!arguments.noRoutes) {
			var routeInjected = injectAdminRoute(pluralLower, getCWD());
			if (routeInjected) {
				detailOutput.update("config/routes.cfm");
			} else {
				detailOutput.skip("config/routes.cfm (admin route already exists or could not inject)");
			}
		}

		// ── 5. Summary ──────────────────────────────────
		detailOutput.success("Admin interface generated! #filesCreated# files created.");

		var nextSteps = [
			"Review the generated controller at app/controllers/admin/#pluralName#.cfc",
			"Review admin views at app/views/admin/#pluralLower#/",
			"CSRF protection is enabled via protectsFromForgery()",
			"Start your server and visit: /admin/#pluralLower#"
		];

		if (arguments.noRoutes) {
			arrayPrepend(nextSteps, "Add admin routes manually to config/routes.cfm");
		}

		detailOutput.nextSteps(nextSteps);
	}

	/**
	 * Generate the admin-namespaced controller from the admin template.
	 * Places the controller in app/controllers/admin/Name.cfc.
	 */
	private struct function generateAdminController(
		required string modelName,
		required struct metadata,
		boolean force = false
	) {
		var pluralName = Helpers.pluralize(arguments.modelName);
		var fileName = pluralName & ".cfc";
		var destDir = getCWD() & "app/controllers/admin/";
		var filePath = destDir & fileName;

		// Check if file exists
		if (fileExists(filePath) && !arguments.force) {
			return {
				success: false,
				error: "Controller file already exists: app/controllers/admin/#fileName#",
				path: filePath
			};
		}

		// Build search WHERE clause from string fields (uses sanitized parameter)
		var searchClauses = [];
		for (var field in arguments.metadata.fields) {
			if (field.isPrimaryKey) continue;
			if (field.dataType == "string" || field.inputType == "text" || field.inputType == "email") {
				arrayAppend(searchClauses, "#field.name# LIKE '%" & chr(35) & "sanitizedQ" & chr(35) & "%'");
			}
		}
		var searchWhereClause = arrayLen(searchClauses)
			? arrayToList(searchClauses, " OR ")
			: "1=1";

		// Build foreign key loader lines for new/edit/create/update actions
		var fkLoaders = [];
		for (var field in arguments.metadata.fields) {
			if (field.isForeignKey && len(field.foreignKeyTo)) {
				var fkModelPlural = lCase(Helpers.pluralize(field.foreignKeyTo));
				arrayAppend(fkLoaders, "#fkModelPlural# = model(""#field.foreignKeyTo#"").findAll(order=""name"");");
			}
		}
		var fkLoaderCode = arrayLen(fkLoaders)
			? chr(9) & chr(9) & arrayToList(fkLoaders, chr(10) & chr(9) & chr(9))
			: "";

		// Read and process the admin controller template
		var templatePath = expandPath("/wheels-cli/templates/admin/AdminControllerContent.txt");
		if (!fileExists(templatePath)) {
			return {
				success: false,
				error: "Admin controller template not found",
				path: ""
			};
		}

		var content = fileRead(templatePath);

		// Replace admin-specific placeholders
		content = replace(content, "|SearchWhereClause|", searchWhereClause, "all");
		content = replace(content, "|ForeignKeyLoaders|", fkLoaderCode, "all");
		content = replace(content, "|DescriptionComment|", "", "all");

		// Replace standard object name placeholders
		content = replace(content, "|ObjectNameSingular|", lCase(arguments.modelName), "all");
		content = replace(content, "|ObjectNamePlural|", lCase(Helpers.pluralize(arguments.modelName)), "all");
		content = replace(content, "|ObjectNameSingularC|", arguments.modelName, "all");
		content = replace(content, "|ObjectNamePluralC|", Helpers.pluralize(arguments.modelName), "all");

		// Ensure directory exists
		if (!directoryExists(destDir)) {
			directoryCreate(destDir, true);
		}

		fileWrite(filePath, content);

		return {
			success: true,
			path: "app/controllers/admin/#fileName#",
			message: "Admin controller generated"
		};
	}

	/**
	 * Inject an admin-scoped resource route into config/routes.cfm.
	 *
	 * Looks for an existing .scope(path="admin") block first.
	 * If found, adds the resource inside it.
	 * If not found, creates the scope block before the CLI-Appends-Here marker.
	 */
	private boolean function injectAdminRoute(
		required string resourceName,
		required string baseDirectory
	) {
		var routesPath = arguments.baseDirectory & "config/routes.cfm";
		if (!fileExists(routesPath)) return false;

		var content = fileRead(routesPath);
		var resourceRoute = '.resources("' & arguments.resourceName & '")';
		var nl = chr(10);
		var tab = chr(9);

		// Check if this resource already exists in admin scope
		if (findNoCase(resourceRoute, content) && findNoCase("admin", content)) {
			return false;
		}

		// Look for existing admin scope block
		var adminScopePattern = '.scope(path="admin"';
		var adminScopeAltPattern = ".scope(path='admin'";

		if (findNoCase(adminScopePattern, content) || findNoCase(adminScopeAltPattern, content)) {
			// Admin scope exists — inject resource before .end() of the admin scope
			// Find the admin scope and inject before its .end()
			var adminScopePos = findNoCase(adminScopePattern, content);
			if (adminScopePos == 0) adminScopePos = findNoCase(adminScopeAltPattern, content);

			// Find the first .end() after the admin scope
			var endPos = findNoCase(".end()", content, adminScopePos);
			if (endPos > 0) {
				// Inject the resource before the .end()
				var beforeEnd = left(content, endPos - 1);
				var afterEnd = mid(content, endPos, len(content) - endPos + 1);
				content = beforeEnd & tab & tab & tab & resourceRoute & nl & tab & tab & afterEnd;
				fileWrite(routesPath, content);
				return true;
			}
		}

		// No existing admin scope — create one before CLI-Appends-Here marker
		var markerPattern = "// CLI-Appends-Here";
		var indent = "";

		// Detect indentation
		if (find(tab & tab & tab & markerPattern, content)) {
			indent = tab & tab & tab;
		} else if (find(tab & tab & markerPattern, content)) {
			indent = tab & tab;
		} else if (find(tab & markerPattern, content)) {
			indent = tab;
		}

		var fullMarker = indent & markerPattern;
		if (find(fullMarker, content)) {
			var adminBlock = indent & '.scope(path="admin", package="admin")' & nl;
			adminBlock &= indent & tab & resourceRoute & nl;
			adminBlock &= indent & ".end()" & nl;
			content = replace(content, fullMarker, adminBlock & fullMarker, "all");
			fileWrite(routesPath, content);
			return true;
		}

		return false;
	}

}
