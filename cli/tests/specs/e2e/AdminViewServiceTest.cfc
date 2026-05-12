/**
 * Tests for AdminViewService: admin index and show view generation.
 *
 * Verifies that AdminViewService generates correct admin view content
 * from model introspection metadata, including:
 *   - Sortable column headers
 *   - Type-aware table cells (boolean, email, date, enum, FK)
 *   - Detail view field rows
 *   - Association sections
 *   - Search form and pagination
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Resolve template directory: cli/src/templates/
		var thisDir = getDirectoryFromPath(getCurrentTemplatePath());
		var File = createObject("java", "java.io.File");
		variables.cliRoot = File.init(thisDir & "../../../").getCanonicalPath();
		variables.templateDir = variables.cliRoot & "/src/templates";

		// Instantiate helpers for name processing
		variables.helpers = new cli.lucli.services.Helpers();

		// Instantiate AdminViewService in standalone mode
		variables.svc = new cli.src.models.AdminViewService(
			helpers = variables.helpers,
			templateDir = variables.templateDir
		);

		// Build a realistic metadata struct matching AdminIntrospectionService.introspect() output
		variables.userMetadata = buildUserMetadata();
	}

	function run() {

		// ── Index View ──────────────────────────────

		describe("Admin Index View", function() {

			beforeEach(function() {
				variables.indexContent = variables.svc.renderIndexContent(variables.userMetadata);
			});

			it("contains page title with plural model name", function() {
				expect(variables.indexContent).toInclude("<h1>Users</h1>");
			});

			it("contains New button with correct route", function() {
				expect(variables.indexContent).toInclude('route="newUser"');
				expect(variables.indexContent).toInclude("New User");
			});

			it("contains search form", function() {
				expect(variables.indexContent).toInclude('name="q"');
				expect(variables.indexContent).toInclude("Search Users");
			});

			it("contains sortable column headers for visible fields", function() {
				expect(variables.indexContent).toInclude('_sortLink("firstName"');
				expect(variables.indexContent).toInclude('"First Name"');
				expect(variables.indexContent).toInclude('_sortLink("email"');
			});

			it("excludes primary key from column headers", function() {
				expect(variables.indexContent).notToInclude('_sortLink("id"');
			});

			it("excludes text fields from list columns", function() {
				// bio is type=text, inList=false
				expect(variables.indexContent).notToInclude('_sortLink("bio"');
			});

			it("renders boolean fields as Yes/No badges", function() {
				expect(variables.indexContent).toInclude("badge bg-success");
				expect(variables.indexContent).toInclude("badge bg-secondary");
				expect(variables.indexContent).toInclude("users.active");
			});

			it("renders email fields as mailto links", function() {
				expect(variables.indexContent).toInclude("mailto:");
				expect(variables.indexContent).toInclude("users.email");
			});

			it("renders datetime fields with dateTimeFormat", function() {
				expect(variables.indexContent).toInclude("dateTimeFormat(users.createdAt");
			});

			it("renders foreign key fields as association name", function() {
				expect(variables.indexContent).toInclude("users.role.name");
			});

			it("renders enum fields as badges", function() {
				expect(variables.indexContent).toInclude("badge bg-info");
				expect(variables.indexContent).toInclude("users.status");
			});

			it("contains pagination", function() {
				expect(variables.indexContent).toInclude("paginationNav()");
			});

			it("contains empty state message", function() {
				expect(variables.indexContent).toInclude("No Users found");
			});

			it("contains action buttons (View, Edit, Delete)", function() {
				expect(variables.indexContent).toInclude('"View"');
				expect(variables.indexContent).toInclude('"Edit"');
				expect(variables.indexContent).toInclude('"Delete"');
			});

			it("contains sort link helper function definition", function() {
				expect(variables.indexContent).toInclude("function _sortLink(");
				expect(variables.indexContent).toInclude("params.sort");
				expect(variables.indexContent).toInclude("params.direction");
			});

			it("uses correct query loop variable", function() {
				expect(variables.indexContent).toInclude('query="users"');
			});
		});

		// ── Show View ───────────────────────────────

		describe("Admin Show View", function() {

			beforeEach(function() {
				variables.showContent = variables.svc.renderShowContent(variables.userMetadata);
			});

			it("contains page title", function() {
				expect(variables.showContent).toInclude("User Detail");
			});

			it("contains Back to List link", function() {
				expect(variables.showContent).toInclude("Back to List");
				expect(variables.showContent).toInclude('route="Users"');
			});

			it("contains Edit button", function() {
				expect(variables.showContent).toInclude('route="editUser"');
			});

			it("displays primary key value", function() {
				expect(variables.showContent).toInclude("user.id");
			});

			it("displays string fields with encodeForHTML", function() {
				expect(variables.showContent).toInclude("encodeForHTML(user.firstName)");
			});

			it("displays boolean fields with yesNoFormat", function() {
				expect(variables.showContent).toInclude("yesNoFormat(user.active)");
			});

			it("displays email fields as mailto links", function() {
				expect(variables.showContent).toInclude("mailto:");
				expect(variables.showContent).toInclude("user.email");
			});

			it("displays datetime fields with dateTimeFormat", function() {
				expect(variables.showContent).toInclude("dateTimeFormat(user.createdAt");
			});

			it("displays foreign key fields as association name", function() {
				expect(variables.showContent).toInclude("user.role.name");
			});

			it("displays enum fields as badges", function() {
				expect(variables.showContent).toInclude("badge bg-info");
				expect(variables.showContent).toInclude("user.status");
			});

			it("displays text fields in text-break div", function() {
				expect(variables.showContent).toInclude("text-break");
				expect(variables.showContent).toInclude("user.bio");
			});

			it("contains hasMany association section", function() {
				expect(variables.showContent).toInclude("Posts");
				expect(variables.showContent).toInclude("Associated posts");
			});

			it("contains hasOne association section", function() {
				expect(variables.showContent).toInclude("Profile");
				expect(variables.showContent).toInclude("Associated profile");
			});

			it("does not contain belongsTo as a section (shown as field)", function() {
				// belongsTo "role" should be displayed as a field via FK, not as a section
				var sectionCount = 0;
				var searchFrom = 1;
				while (findNoCase("Associated role", variables.showContent, searchFrom) > 0) {
					sectionCount++;
					searchFrom = findNoCase("Associated role", variables.showContent, searchFrom) + 1;
				}
				expect(sectionCount).toBe(0, "belongsTo should not generate a section");
			});

			it("contains Delete button", function() {
				expect(variables.showContent).toInclude("Delete User");
				expect(variables.showContent).toInclude('method="delete"');
			});

			it("shows all field labels", function() {
				expect(variables.showContent).toInclude("First Name");
				expect(variables.showContent).toInclude("Last Name");
				expect(variables.showContent).toInclude("Email");
				expect(variables.showContent).toInclude("Active");
			});
		});

		// ── Edge Cases ──────────────────────────────

		describe("Edge Cases", function() {

			it("handles model with no associations", function() {
				var meta = {
					modelName: "Tag",
					pluralName: "Tags",
					displayName: "Tag",
					displayNamePlural: "Tags",
					tableName: "tags",
					primaryKey: "id",
					softDeletion: false,
					fields: [
						{name: "id", label: "Id", dataType: "integer", inputType: "number",
						 isPrimaryKey: true, isForeignKey: false, foreignKeyTo: "",
						 isEnum: false, enumValues: {}, inList: false, inForm: false, inShow: true,
						 required: false, unique: false, validations: {},
						 column: "id", sqlType: "cf_sql_integer", maxLength: 0, nullable: false,
						 defaultValue: "", scale: 0},
						{name: "name", label: "Name", dataType: "string", inputType: "text",
						 isPrimaryKey: false, isForeignKey: false, foreignKeyTo: "",
						 isEnum: false, enumValues: {}, inList: true, inForm: true, inShow: true,
						 required: true, unique: false, validations: {},
						 column: "name", sqlType: "cf_sql_varchar", maxLength: 255, nullable: false,
						 defaultValue: "", scale: 0}
					],
					associations: [],
					validationSummary: {},
					enums: {},
					scopes: []
				};

				var indexContent = variables.svc.renderIndexContent(meta);
				expect(indexContent).toInclude("Tags");
				expect(indexContent).toInclude('_sortLink("name"');

				var showContent = variables.svc.renderShowContent(meta);
				expect(showContent).toInclude("Tag Detail");
				// No association sections
				expect(showContent).notToInclude("Associated");
			});

			it("handles model with only primary key", function() {
				var meta = {
					modelName: "Session",
					pluralName: "Sessions",
					displayName: "Session",
					displayNamePlural: "Sessions",
					tableName: "sessions",
					primaryKey: "id",
					softDeletion: false,
					fields: [
						{name: "id", label: "Id", dataType: "integer", inputType: "number",
						 isPrimaryKey: true, isForeignKey: false, foreignKeyTo: "",
						 isEnum: false, enumValues: {}, inList: false, inForm: false, inShow: true,
						 required: false, unique: false, validations: {},
						 column: "id", sqlType: "cf_sql_integer", maxLength: 0, nullable: false,
						 defaultValue: "", scale: 0}
					],
					associations: [],
					validationSummary: {},
					enums: {},
					scopes: []
				};

				var indexContent = variables.svc.renderIndexContent(meta);
				expect(indexContent).toInclude("Sessions");
				// Only action column header since PK is excluded
				expect(indexContent).toInclude("Actions");
			});
		});
	}

	// ── Test data builder ───────────────────────

	/**
	 * Build a realistic User model metadata struct matching
	 * the output of AdminIntrospectionService.introspect().
	 */
	private struct function buildUserMetadata() {
		return {
			modelName: "User",
			pluralName: "Users",
			displayName: "User",
			displayNamePlural: "Users",
			tableName: "users",
			primaryKey: "id",
			softDeletion: false,
			fields: [
				// Primary key
				{name: "id", label: "Id", dataType: "integer", inputType: "number",
				 isPrimaryKey: true, isForeignKey: false, foreignKeyTo: "",
				 isEnum: false, enumValues: {}, inList: false, inForm: false, inShow: true,
				 required: false, unique: false, validations: {},
				 column: "id", sqlType: "cf_sql_integer", maxLength: 0, nullable: false,
				 defaultValue: "", scale: 0},
				// String field
				{name: "firstName", label: "First Name", dataType: "string", inputType: "text",
				 isPrimaryKey: false, isForeignKey: false, foreignKeyTo: "",
				 isEnum: false, enumValues: {}, inList: true, inForm: true, inShow: true,
				 required: true, unique: false, validations: {presence: true},
				 column: "firstName", sqlType: "cf_sql_varchar", maxLength: 255, nullable: false,
				 defaultValue: "", scale: 0},
				// String field
				{name: "lastName", label: "Last Name", dataType: "string", inputType: "text",
				 isPrimaryKey: false, isForeignKey: false, foreignKeyTo: "",
				 isEnum: false, enumValues: {}, inList: true, inForm: true, inShow: true,
				 required: true, unique: false, validations: {presence: true},
				 column: "lastName", sqlType: "cf_sql_varchar", maxLength: 255, nullable: false,
				 defaultValue: "", scale: 0},
				// Email field
				{name: "email", label: "Email", dataType: "string", inputType: "email",
				 isPrimaryKey: false, isForeignKey: false, foreignKeyTo: "",
				 isEnum: false, enumValues: {}, inList: true, inForm: true, inShow: true,
				 required: true, unique: true, validations: {presence: true, uniqueness: true},
				 column: "email", sqlType: "cf_sql_varchar", maxLength: 255, nullable: false,
				 defaultValue: "", scale: 0},
				// Foreign key
				{name: "roleId", label: "Role Id", dataType: "integer", inputType: "select",
				 isPrimaryKey: false, isForeignKey: true, foreignKeyTo: "Role",
				 isEnum: false, enumValues: {}, inList: true, inForm: true, inShow: true,
				 required: false, unique: false, validations: {},
				 column: "roleId", sqlType: "cf_sql_integer", maxLength: 0, nullable: true,
				 defaultValue: "", scale: 0},
				// Boolean
				{name: "active", label: "Active", dataType: "boolean", inputType: "checkbox",
				 isPrimaryKey: false, isForeignKey: false, foreignKeyTo: "",
				 isEnum: false, enumValues: {}, inList: true, inForm: true, inShow: true,
				 required: false, unique: false, validations: {},
				 column: "active", sqlType: "cf_sql_bit", maxLength: 0, nullable: false,
				 defaultValue: "1", scale: 0},
				// Enum
				{name: "status", label: "Status", dataType: "string", inputType: "select",
				 isPrimaryKey: false, isForeignKey: false, foreignKeyTo: "",
				 isEnum: true, enumValues: {active: "active", inactive: "inactive", banned: "banned"},
				 inList: true, inForm: true, inShow: true,
				 required: false, unique: false, validations: {},
				 column: "status", sqlType: "cf_sql_varchar", maxLength: 50, nullable: true,
				 defaultValue: "active", scale: 0},
				// Text (large field)
				{name: "bio", label: "Bio", dataType: "text", inputType: "textarea",
				 isPrimaryKey: false, isForeignKey: false, foreignKeyTo: "",
				 isEnum: false, enumValues: {}, inList: false, inForm: true, inShow: true,
				 required: false, unique: false, validations: {},
				 column: "bio", sqlType: "cf_sql_longvarchar", maxLength: 0, nullable: true,
				 defaultValue: "", scale: 0},
				// Datetime
				{name: "createdAt", label: "Created At", dataType: "datetime", inputType: "datetime-local",
				 isPrimaryKey: false, isForeignKey: false, foreignKeyTo: "",
				 isEnum: false, enumValues: {}, inList: true, inForm: false, inShow: true,
				 required: false, unique: false, validations: {},
				 column: "createdAt", sqlType: "cf_sql_timestamp", maxLength: 0, nullable: true,
				 defaultValue: "", scale: 0}
			],
			associations: [
				{name: "role", type: "belongsTo", modelName: "Role",
				 foreignKey: "roleId", joinKey: "", dependent: "", nested: {}},
				{name: "posts", type: "hasMany", modelName: "Post",
				 foreignKey: "userId", joinKey: "", dependent: "delete", nested: {}},
				{name: "profile", type: "hasOne", modelName: "Profile",
				 foreignKey: "userId", joinKey: "", dependent: "", nested: {}}
			],
			validationSummary: {
				firstName: {presence: true},
				lastName: {presence: true},
				email: {presence: true, uniqueness: true}
			},
			enums: {
				status: {values: {active: "active", inactive: "inactive", banned: "banned"}}
			},
			scopes: []
		};
	}

}
