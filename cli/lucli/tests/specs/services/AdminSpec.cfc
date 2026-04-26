component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.moduleRoot = expandPath("/cli/lucli/");
		variables.helpers = new modules.wheels.services.Helpers();
		variables.admin = new modules.wheels.services.Admin(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot,
			moduleRoot = variables.moduleRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Admin Service", () => {

			// mapColumnToFormHelper() is private — test via generated _form.cfm content

			describe("mapColumnToFormHelper() — via generated form", () => {

				it("maps string type to textField", () => {
					var modelData = {
						model: "FormHelperStr",
						tableName: "form_helper_strs",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "title", type: "string"}
						],
						associations: []
					};
					var result = admin.generateAdmin(modelData = modelData, force = true, noRoutes = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/form_helper_strs/_form.cfm");
					expect(formContent).toInclude("textField");
				});

				it("maps text type to textArea", () => {
					var modelData = {
						model: "FormHelperTxt",
						tableName: "form_helper_txts",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "body", type: "text"}
						],
						associations: []
					};
					var result = admin.generateAdmin(modelData = modelData, force = true, noRoutes = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/form_helper_txts/_form.cfm");
					expect(formContent).toInclude("textArea");
				});

				it("maps boolean type to checkBox", () => {
					var modelData = {
						model: "FormHelperBool",
						tableName: "form_helper_bools",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "active", type: "boolean"}
						],
						associations: []
					};
					var result = admin.generateAdmin(modelData = modelData, force = true, noRoutes = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/form_helper_bools/_form.cfm");
					expect(formContent).toInclude("checkBox");
				});

				it("maps integer type to numberField", () => {
					var modelData = {
						model: "FormHelperInt",
						tableName: "form_helper_ints",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "quantity", type: "integer"}
						],
						associations: []
					};
					var result = admin.generateAdmin(modelData = modelData, force = true, noRoutes = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/form_helper_ints/_form.cfm");
					expect(formContent).toInclude("numberField");
				});

				it("maps date type to dateField", () => {
					var modelData = {
						model: "FormHelperDt",
						tableName: "form_helper_dts",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "startDate", type: "date"}
						],
						associations: []
					};
					var result = admin.generateAdmin(modelData = modelData, force = true, noRoutes = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/form_helper_dts/_form.cfm");
					expect(formContent).toInclude("dateField");
				});

				it("maps datetime to dateTimeLocalField", () => {
					var modelData = {
						model: "FormHelperDtl",
						tableName: "form_helper_dtls",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "publishedAt", type: "datetime"}
						],
						associations: []
					};
					var result = admin.generateAdmin(modelData = modelData, force = true, noRoutes = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/form_helper_dtls/_form.cfm");
					expect(formContent).toInclude("dateTimeLocalField");
				});

				it("maps email column name to emailField", () => {
					var modelData = {
						model: "FormHelperEmail",
						tableName: "form_helper_emails",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "email", type: "string"}
						],
						associations: []
					};
					var result = admin.generateAdmin(modelData = modelData, force = true, noRoutes = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/form_helper_emails/_form.cfm");
					expect(formContent).toInclude("emailField");
				});

				it("maps phone column name to telField", () => {
					var modelData = {
						model: "FormHelperPhone",
						tableName: "form_helper_phones",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "phone", type: "string"}
						],
						associations: []
					};
					var result = admin.generateAdmin(modelData = modelData, force = true, noRoutes = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/form_helper_phones/_form.cfm");
					expect(formContent).toInclude("telField");
				});

				it("maps website column name to urlField", () => {
					var modelData = {
						model: "FormHelperUrl",
						tableName: "form_helper_urls",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "website", type: "string"}
						],
						associations: []
					};
					var result = admin.generateAdmin(modelData = modelData, force = true, noRoutes = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/form_helper_urls/_form.cfm");
					expect(formContent).toInclude("urlField");
				});

			});

			describe("generateAdmin()", () => {

				it("generates controller and view files", () => {
					var modelData = {
						model: "Product",
						tableName: "products",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "name", type: "string"},
							{name: "price", type: "decimal"},
							{name: "active", type: "boolean"},
							{name: "createdAt", type: "datetime"},
							{name: "updatedAt", type: "datetime"}
						],
						associations: []
					};

					var result = admin.generateAdmin(modelData = modelData, force = true);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.generated)).toBeGTE(6);

					// Verify controller exists
					expect(fileExists(tempRoot & "/app/controllers/admin/Products.cfc")).toBeTrue();

					// Verify views exist
					expect(fileExists(tempRoot & "/app/views/admin/products/index.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/admin/products/show.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/admin/products/new.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/admin/products/edit.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/admin/products/_form.cfm")).toBeTrue();
				});

				it("excludes id and timestamp columns from form fields", () => {
					var modelData = {
						model: "Item",
						tableName: "items",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "title", type: "string"},
							{name: "createdAt", type: "datetime"},
							{name: "updatedAt", type: "datetime"}
						],
						associations: []
					};

					var result = admin.generateAdmin(modelData = modelData, force = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/items/_form.cfm");
					expect(formContent).toInclude("title");
					expect(formContent).notToInclude('"id"');
					expect(formContent).notToInclude('"createdAt"');
					expect(formContent).notToInclude('"updatedAt"');
				});

				it("generates foreign key loaders for belongsTo associations", () => {
					var modelData = {
						model: "Post",
						tableName: "posts",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "title", type: "string"},
							{name: "categoryId", type: "integer"}
						],
						associations: [
							{type: "belongsTo", name: "category", modelName: "Category"}
						]
					};

					var result = admin.generateAdmin(modelData = modelData, force = true);
					var controllerContent = fileRead(tempRoot & "/app/controllers/admin/Posts.cfc");
					expect(controllerContent).toInclude("loadCategories");
					expect(controllerContent).toInclude('model("Category")');
				});

				it("injects admin route into routes.cfm", () => {
					var modelData = {
						model: "Order",
						tableName: "orders",
						primaryKey: "id",
						columns: [{name: "id", type: "integer", primaryKey: true}],
						associations: []
					};

					var result = admin.generateAdmin(modelData = modelData, force = true);
					var routesContent = fileRead(tempRoot & "/config/routes.cfm");
					expect(routesContent).toInclude('scope(path="admin"');
					expect(routesContent).toInclude('.resources("orders")');
				});

				it("errors when files exist and force is false", () => {
					var modelData = {
						model: "Order",
						tableName: "orders",
						primaryKey: "id",
						columns: [{name: "id", type: "integer", primaryKey: true}],
						associations: []
					};

					// Files already exist from previous test
					var result = admin.generateAdmin(modelData = modelData, force = false);
					expect(result.success).toBeFalse();
					expect(arrayLen(result.errors)).toBeGT(0);
				});

				it("skips route injection with noRoutes flag", () => {
					var routesBefore = fileRead(tempRoot & "/config/routes.cfm");

					var modelData = {
						model: "NoRouteTest",
						tableName: "no_route_tests",
						primaryKey: "id",
						columns: [{name: "id", type: "integer", primaryKey: true}],
						associations: []
					};

					var result = admin.generateAdmin(
						modelData = modelData,
						force = true,
						noRoutes = true
					);
					expect(result.success).toBeTrue();

					var routesAfter = fileRead(tempRoot & "/config/routes.cfm");
					expect(routesAfter).notToInclude("no_route_tests");
				});

			});

		});

	}

}
