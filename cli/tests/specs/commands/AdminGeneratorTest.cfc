/**
 * Tests for the admin generator: controller template processing and route injection.
 *
 * Tests the AdminControllerContent.txt template placeholder replacement and
 * the route injection logic for admin-scoped resources.
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Resolve paths
		var thisDir = getDirectoryFromPath(getCurrentTemplatePath());
		var File = createObject("java", "java.io.File");
		variables.cliRoot = File.init(thisDir & "../../../").getCanonicalPath();
		variables.templateDir = variables.cliRoot & "/src/templates";
		variables.templatePath = variables.templateDir & "/admin/AdminControllerContent.txt";

		// Create a temp directory for route injection tests
		variables.tempDir = getTempDirectory() & "admin_gen_test_" & createUUID() & "/";
		directoryCreate(variables.tempDir, true);
		directoryCreate(variables.tempDir & "config/", true);
	}

	function afterAll() {
		if (directoryExists(variables.tempDir)) {
			directoryDelete(variables.tempDir, true);
		}
	}

	function run() {

		// ── Controller template ──────────────────────

		describe("Admin controller template", function() {

			it("exists at expected path", function() {
				expect(fileExists(variables.templatePath)).toBeTrue();
			});

			it("extends app.controllers.Controller", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude('extends="app.controllers.Controller"');
			});

			it("calls super.config()", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude("super.config()");
			});

			it("calls protectsFromForgery()", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude("protectsFromForgery()");
			});

			it("includes verifies for member actions", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude('verifies(except="index,new,create"');
				expect(content).toInclude('params="key"');
			});

			it("contains all CRUD actions", function() {
				var content = fileRead(variables.templatePath);
				var actions = ["index", "show", "new", "create", "edit", "update", "delete"];
				for (var action in actions) {
					expect(content).toInclude('function #action#()');
				}
			});

			it("contains objectNotFound handler as private", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude("private function objectNotFound()");
			});

			it("includes search sanitization", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude("sanitizedQ");
				expect(content).toInclude("ReplaceList");
			});

			it("includes sort parameter validation", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude("validDirection");
				expect(content).toInclude("reFindNoCase");
			});

			it("includes pagination support", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude("params.page");
				expect(content).toInclude("perPage");
			});

			it("has SearchWhereClause placeholder", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude("|SearchWhereClause|");
			});

			it("has ForeignKeyLoaders placeholder", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude("|ForeignKeyLoaders|");
			});

			it("has ObjectName placeholders for model binding", function() {
				var content = fileRead(variables.templatePath);
				expect(content).toInclude("|ObjectNameSingular|");
				expect(content).toInclude("|ObjectNamePlural|");
				expect(content).toInclude("|ObjectNameSingularC|");
				expect(content).toInclude("|ObjectNamePluralC|");
			});
		});

		// ── Template placeholder replacement ─────────

		describe("Admin controller template replacement", function() {

			it("replaces object name placeholders correctly", function() {
				var content = fileRead(variables.templatePath);
				content = replace(content, "|ObjectNameSingular|", "product", "all");
				content = replace(content, "|ObjectNamePlural|", "products", "all");
				content = replace(content, "|ObjectNameSingularC|", "Product", "all");
				content = replace(content, "|ObjectNamePluralC|", "Products", "all");
				content = replace(content, "|SearchWhereClause|", "name LIKE '%##sanitizedQ##%'", "all");
				content = replace(content, "|ForeignKeyLoaders|", "", "all");
				content = replace(content, "|DescriptionComment|", "", "all");

				expect(content).toInclude('model("Product").findAll(');
				expect(content).toInclude('model("Product").findByKey(');
				expect(content).toInclude('model("Product").new()');
				expect(content).toInclude("params.product");
				expect(content).toInclude("product.hasErrors()");
				expect(content).toInclude("product.update(params.product)");
				expect(content).toInclude("Products successfully created");
			});

			it("injects search WHERE clause", function() {
				var content = fileRead(variables.templatePath);
				var searchClause = "firstName LIKE '%##sanitizedQ##%' OR email LIKE '%##sanitizedQ##%'";
				content = replace(content, "|SearchWhereClause|", searchClause, "all");

				expect(content).toInclude("firstName LIKE");
				expect(content).toInclude("email LIKE");
			});

			it("injects foreign key loaders", function() {
				var content = fileRead(variables.templatePath);
				var loaderCode = chr(9) & chr(9) & 'roles = model("Role").findAll(order="name");';
				content = replace(content, "|ForeignKeyLoaders|", loaderCode, "all");

				expect(content).toInclude('model("Role").findAll(');
			});
		});

		// ── Route injection ──────────────────────────

		describe("Admin route injection", function() {

			beforeEach(function() {
				// Reset the routes file for each test
			});

			it("creates admin scope when none exists", function() {
				var routesContent = '<cfscript>' & chr(10)
					& chr(9) & 'mapper()' & chr(10)
					& chr(9) & chr(9) & '// CLI-Appends-Here' & chr(10)
					& chr(9) & chr(9) & '.root(to = "main##index", method = "get")' & chr(10)
					& chr(9) & '.end();' & chr(10)
					& '</cfscript>';
				var routesPath = variables.tempDir & "config/routes.cfm";
				fileWrite(routesPath, routesContent);

				var result = injectAdminRoute("products", routesPath);

				expect(result).toBeTrue();
				var updated = fileRead(routesPath);
				expect(updated).toInclude('.scope(path="admin", package="admin")');
				expect(updated).toInclude('.resources("products")');
				expect(updated).toInclude(".end()");
			});

			it("adds resource to existing admin scope", function() {
				var routesContent = '<cfscript>' & chr(10)
					& chr(9) & 'mapper()' & chr(10)
					& chr(9) & chr(9) & '.scope(path="admin", package="admin")' & chr(10)
					& chr(9) & chr(9) & chr(9) & '.resources("users")' & chr(10)
					& chr(9) & chr(9) & '.end()' & chr(10)
					& chr(9) & '.end();' & chr(10)
					& '</cfscript>';
				var routesPath = variables.tempDir & "config/routes.cfm";
				fileWrite(routesPath, routesContent);

				var result = injectAdminRoute("products", routesPath);

				expect(result).toBeTrue();
				var updated = fileRead(routesPath);
				expect(updated).toInclude('.resources("products")');
				expect(updated).toInclude('.resources("users")');
			});

			it("skips injection when resource already exists", function() {
				var routesContent = '<cfscript>' & chr(10)
					& chr(9) & 'mapper()' & chr(10)
					& chr(9) & chr(9) & '.scope(path="admin", package="admin")' & chr(10)
					& chr(9) & chr(9) & chr(9) & '.resources("products")' & chr(10)
					& chr(9) & chr(9) & '.end()' & chr(10)
					& chr(9) & '.end();' & chr(10)
					& '</cfscript>';
				var routesPath = variables.tempDir & "config/routes.cfm";
				fileWrite(routesPath, routesContent);

				var result = injectAdminRoute("products", routesPath);

				expect(result).toBeFalse();
			});
		});
	}

	/**
	 * Standalone route injection for testing — mirrors admin.cfc injectAdminRoute logic.
	 */
	private boolean function injectAdminRoute(
		required string resourceName,
		required string routesPath
	) {
		if (!fileExists(arguments.routesPath)) return false;

		var content = fileRead(arguments.routesPath);
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
			var adminScopePos = findNoCase(adminScopePattern, content);
			if (adminScopePos == 0) adminScopePos = findNoCase(adminScopeAltPattern, content);

			var endPos = findNoCase(".end()", content, adminScopePos);
			if (endPos > 0) {
				var beforeEnd = left(content, endPos - 1);
				var afterEnd = mid(content, endPos, len(content) - endPos + 1);
				content = beforeEnd & tab & tab & tab & resourceRoute & nl & tab & tab & afterEnd;
				fileWrite(arguments.routesPath, content);
				return true;
			}
		}

		// No existing admin scope — create one before CLI-Appends-Here marker
		var markerPattern = "// CLI-Appends-Here";
		var indent = "";

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
			fileWrite(arguments.routesPath, content);
			return true;
		}

		return false;
	}

}
