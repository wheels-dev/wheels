/**
 * Tests for the api-resource command
 * Tests model and controller generation for API resources
 */
component extends="BaseCommandSpec" {
	
	function run() {
		
		describe("API Resource Command", () => {
			
			beforeEach(() => {
				// Create mock command instance
				variables.apiResource = createMockCommand("cli.commands.wheels.api-resource");
				
				// Create basic app structure
				createDirectoryStructure([
					"app/models",
					"app/controllers",
					"db/migrate",
					"tests/models",
					"tests/controllers"
				]);
				
				// Mock database schema for field type inference
				variables.mockSchema = [
					{
						tableName: "products",
						columns: [
							{name: "id", type: "integer", isPrimaryKey: true},
							{name: "name", type: "varchar", length: 255},
							{name: "price", type: "decimal", precision: 10, scale: 2},
							{name: "active", type: "boolean", default: true},
							{name: "createdAt", type: "timestamp"},
							{name: "updatedAt", type: "timestamp"}
						]
					}
				];
			});
			
			describe("Basic Resource Generation", () => {
				
				it("should generate model with validations", () => {
					// Run the command
					apiResource.run(
						name = "Product",
						fields = "name:string,price:decimal,active:boolean"
					);
					
					// Check that model was created
					assertFileExists("app/models/Product.cfc");
					
					// Verify model content
					var modelContent = getFileContent("app/models/Product.cfc");
					expect(modelContent).toInclude("component extends=\"app.models.Model\"");
					expect(modelContent).toInclude("function config()");
					expect(modelContent).toInclude("table(\"products\")");
					
					// Verify validations
					expect(modelContent).toInclude("validatesPresenceOf(\"name\")");
					expect(modelContent).toInclude("validatesNumericalityOf(\"price\")");
					expect(modelContent).toInclude("validatesInclusionOf(property=\"active\", list=\"true,false\")");
				});
				
				it("should generate API controller with CRUD actions", () => {
					// Run the command
					apiResource.run(
						name = "Product",
						fields = "name:string,price:decimal"
					);
					
					// Check that controller was created
					assertFileExists("app/controllers/Products.cfc");
					
					// Verify controller content
					var controllerContent = getFileContent("app/controllers/Products.cfc");
					expect(controllerContent).toInclude("component extends=\"app.controllers.Controller\"");
					expect(controllerContent).toInclude("function config()");
					expect(controllerContent).toInclude("provides(\"json\")");
					
					// Verify CRUD actions
					expect(controllerContent).toInclude("function index()");
					expect(controllerContent).toInclude("function show()");
					expect(controllerContent).toInclude("function create()");
					expect(controllerContent).toInclude("function update()");
					expect(controllerContent).toInclude("function delete()");
					
					// Verify JSON responses
					expect(controllerContent).toInclude("renderWith(products)");
					expect(controllerContent).toInclude("renderWith(product)");
				});
				
				it("should generate database migration", () => {
					// Run the command
					apiResource.run(
						name = "Product",
						fields = "name:string,price:decimal,active:boolean"
					);
					
					// Check that migration was created
					var migrationFiles = directoryList(variables.tempDir & "db/migrate", false, "name", "*.cfc");
					expect(arrayLen(migrationFiles)).toBe(1);
					expect(migrationFiles[1]).toInclude("create_products_table");
					
					// Verify migration content
					var migrationContent = getFileContent("db/migrate/" & migrationFiles[1]);
					expect(migrationContent).toInclude("function up()");
					expect(migrationContent).toInclude("function down()");
					expect(migrationContent).toInclude("t.create(\"products\")");
					expect(migrationContent).toInclude("t.string(\"name\")");
					expect(migrationContent).toInclude("t.decimal(\"price\")");
					expect(migrationContent).toInclude("t.boolean(\"active\")");
					expect(migrationContent).toInclude("t.timestamps()");
				});
				
			});
			
			describe("Field Types and Validations", () => {
				
				it("should handle all supported field types", () => {
					// Run the command with various field types
					apiResource.run(
						name = "User",
						fields = "email:string,age:integer,balance:decimal,active:boolean,birthDate:date,bio:text"
					);
					
					// Verify model validations for each type
					var modelContent = getFileContent("app/models/User.cfc");
					expect(modelContent).toInclude("validatesFormatOf(\"email\", type=\"email\")");
					expect(modelContent).toInclude("validatesNumericalityOf(\"age\", onlyInteger=true)");
					expect(modelContent).toInclude("validatesNumericalityOf(\"balance\")");
					expect(modelContent).toInclude("validatesInclusionOf(property=\"active\", list=\"true,false\")");
					expect(modelContent).toInclude("validatesFormatOf(\"birthDate\", type=\"date\")");
				});
				
				it("should add length validations for string fields", () => {
					// Run the command with string length
					apiResource.run(
						name = "Article",
						fields = "title:string:100,slug:string:50"
					);
					
					// Verify length validations
					var modelContent = getFileContent("app/models/Article.cfc");
					expect(modelContent).toInclude("validatesLengthOf(property=\"title\", maximum=100)");
					expect(modelContent).toInclude("validatesLengthOf(property=\"slug\", maximum=50)");
				});
				
				it("should handle required fields", () => {
					// Run the command with required fields
					apiResource.run(
						name = "Post",
						fields = "title:string:required,content:text,author:string:required"
					);
					
					// Verify presence validations
					var modelContent = getFileContent("app/models/Post.cfc");
					expect(modelContent).toInclude("validatesPresenceOf(\"title,author\")");
					expect(modelContent).notToInclude("validatesPresenceOf(\"content\")");
				});
				
			});
			
			describe("Associations", () => {
				
				it("should detect and create belongsTo associations", () => {
					// Run the command with foreign key fields
					apiResource.run(
						name = "Comment",
						fields = "content:text,userId:integer,postId:integer"
					);
					
					// Verify associations
					var modelContent = getFileContent("app/models/Comment.cfc");
					expect(modelContent).toInclude("belongsTo(\"user\")");
					expect(modelContent).toInclude("belongsTo(\"post\")");
				});
				
				it("should create hasMany associations with --has-many flag", () => {
					// Run the command with hasMany option
					apiResource.run(
						name = "User",
						fields = "name:string,email:string",
						hasMany = "posts,comments"
					);
					
					// Verify associations
					var modelContent = getFileContent("app/models/User.cfc");
					expect(modelContent).toInclude("hasMany(\"posts\")");
					expect(modelContent).toInclude("hasMany(\"comments\")");
				});
				
				it("should handle polymorphic associations", () => {
					// Run the command with polymorphic fields
					apiResource.run(
						name = "Image",
						fields = "url:string,imageableType:string,imageableId:integer"
					);
					
					// Verify polymorphic association
					var modelContent = getFileContent("app/models/Image.cfc");
					expect(modelContent).toInclude("belongsTo(name=\"imageable\", polymorphic=true)");
				});
				
			});
			
			describe("API-Specific Features", () => {
				
				it("should add pagination to index action", () => {
					// Run the command
					apiResource.run(
						name = "Product",
						fields = "name:string"
					);
					
					// Verify pagination
					var controllerContent = getFileContent("app/controllers/Products.cfc");
					expect(controllerContent).toInclude("findAll(page=params.page, perPage=params.perPage)");
					expect(controllerContent).toInclude("params.page ?: 1");
					expect(controllerContent).toInclude("params.perPage ?: 25");
				});
				
				it("should add filtering support", () => {
					// Run the command with filter option
					apiResource.run(
						name = "Product",
						fields = "name:string,category:string,active:boolean",
						filterable = "name,category,active"
					);
					
					// Verify filtering logic
					var controllerContent = getFileContent("app/controllers/Products.cfc");
					expect(controllerContent).toInclude("local.where = {}");
					expect(controllerContent).toInclude("if (structKeyExists(params, \"name\"))");
					expect(controllerContent).toInclude("if (structKeyExists(params, \"category\"))");
					expect(controllerContent).toInclude("if (structKeyExists(params, \"active\"))");
					expect(controllerContent).toInclude("findAll(where=local.where");
				});
				
				it("should add sorting support", () => {
					// Run the command with sortable option
					apiResource.run(
						name = "Product",
						fields = "name:string,price:decimal,createdAt:datetime",
						sortable = "name,price,createdAt"
					);
					
					// Verify sorting logic
					var controllerContent = getFileContent("app/controllers/Products.cfc");
					expect(controllerContent).toInclude("params.sort ?: \"createdAt DESC\"");
					expect(controllerContent).toInclude("findAll(order=params.sort");
				});
				
				it("should add search functionality", () => {
					// Run the command with searchable option
					apiResource.run(
						name = "Product",
						fields = "name:string,description:text",
						searchable = "name,description"
					);
					
					// Verify search logic
					var controllerContent = getFileContent("app/controllers/Products.cfc");
					expect(controllerContent).toInclude("if (structKeyExists(params, \"q\"))");
					expect(controllerContent).toInclude("local.where.name = {operator=\"LIKE\", value=\"%#params.q#%\"}");
					expect(controllerContent).toInclude("OR description LIKE");
				});
				
			});
			
			describe("Authentication and Authorization", () => {
				
				it("should add authentication filters when specified", () => {
					// Run the command with auth option
					apiResource.run(
						name = "Product",
						fields = "name:string",
						authenticate = true
					);
					
					// Verify authentication filter
					var controllerContent = getFileContent("app/controllers/Products.cfc");
					expect(controllerContent).toInclude("filters(through=\"authenticateRequest\")");
				});
				
				it("should add authorization for specific actions", () => {
					// Run the command with authorization option
					apiResource.run(
						name = "Product",
						fields = "name:string",
						authorize = "create,update,delete"
					);
					
					// Verify authorization filters
					var controllerContent = getFileContent("app/controllers/Products.cfc");
					expect(controllerContent).toInclude("filters(through=\"authorizeAction\", only=\"create,update,delete\")");
				});
				
			});
			
			describe("Versioning", () => {
				
				it("should create versioned API controllers", () => {
					// Run the command with version option
					apiResource.run(
						name = "Product",
						fields = "name:string",
						version = "v1"
					);
					
					// Check that versioned directory was created
					assertDirectoryExists("app/controllers/api/v1");
					assertFileExists("app/controllers/api/v1/Products.cfc");
					
					// Verify namespaced controller
					var controllerContent = getFileContent("app/controllers/api/v1/Products.cfc");
					expect(controllerContent).toInclude("component extends=\"app.controllers.Controller\"");
				});
				
			});
			
			describe("Test Generation", () => {
				
				it("should generate model tests", () => {
					// Run the command
					apiResource.run(
						name = "Product",
						fields = "name:string,price:decimal"
					);
					
					// Check that model test was created
					assertFileExists("tests/models/ProductTest.cfc");
					
					// Verify test content
					var testContent = getFileContent("tests/models/ProductTest.cfc");
					expect(testContent).toInclude("component extends=\"tests.BaseSpec\"");
					expect(testContent).toInclude("describe(\"Product Model\")");
					expect(testContent).toInclude("it(\"should validate presence of name\")");
					expect(testContent).toInclude("it(\"should validate numericality of price\")");
				});
				
				it("should generate controller tests", () => {
					// Run the command
					apiResource.run(
						name = "Product",
						fields = "name:string"
					);
					
					// Check that controller test was created
					assertFileExists("tests/controllers/ProductsTest.cfc");
					
					// Verify test content
					var testContent = getFileContent("tests/controllers/ProductsTest.cfc");
					expect(testContent).toInclude("describe(\"Products Controller\")");
					expect(testContent).toInclude("describe(\"GET /products\")");
					expect(testContent).toInclude("describe(\"POST /products\")");
					expect(testContent).toInclude("describe(\"PUT /products/:id\")");
					expect(testContent).toInclude("describe(\"DELETE /products/:id\")");
				});
				
			});
			
			describe("Error Handling", () => {
				
				it("should validate resource name", () => {
					// Run the command with invalid name
					apiResource.run(name = "");
					
					// Verify error message
					assertOutputContains("Resource name is required");
				});
				
				it("should validate field syntax", () => {
					// Run the command with invalid field syntax
					apiResource.run(
						name = "Product",
						fields = "name:invalid_type"
					);
					
					// Verify error message
					assertOutputContains("Invalid field type: invalid_type");
				});
				
				it("should handle existing files", () => {
					// Create existing model
					createTestFile("app/models/Product.cfc", "// Existing model");
					
					// Run the command
					apiResource.run(
						name = "Product",
						fields = "name:string"
					);
					
					// Verify warning message
					assertOutputContains("Product.cfc already exists");
				});
				
			});
			
			describe("Output Messages", () => {
				
				it("should display created files summary", () => {
					// Run the command
					apiResource.run(
						name = "Product",
						fields = "name:string,price:decimal"
					);
					
					// Verify output
					assertOutputContains("API resource created successfully");
					assertOutputContains("Model: app/models/Product.cfc");
					assertOutputContains("Controller: app/controllers/Products.cfc");
					assertOutputContains("Migration:");
					assertOutputContains("Model Test: tests/models/ProductTest.cfc");
					assertOutputContains("Controller Test: tests/controllers/ProductsTest.cfc");
				});
				
				it("should display next steps", () => {
					// Run the command
					apiResource.run(
						name = "Product",
						fields = "name:string"
					);
					
					// Verify next steps
					assertOutputContains("Next steps:");
					assertOutputContains("Run migrations: wheels dbmigrate latest");
					assertOutputContains("Add routes to config/routes.cfm");
					assertOutputContains("resources(\"products\")");
				});
				
			});
			
		});
		
	}
	
}