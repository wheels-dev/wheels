component extends="wheels.WheelsTest" {

	function beforeAll() {
		g = application.wo;
		autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
	}

	function run() {

		describe("AutoMigrator", () => {

			describe("$cfSqlTypeToMigrationType", () => {

				it("maps cf_sql_integer to integer", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_integer")).toBe("integer");
				});

				it("maps cf_sql_varchar to string", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_varchar")).toBe("string");
				});

				it("maps cf_sql_longvarchar to text", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_longvarchar")).toBe("text");
				});

				it("maps cf_sql_timestamp to datetime", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_timestamp")).toBe("datetime");
				});

				it("maps cf_sql_date to date", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_date")).toBe("date");
				});

				it("maps cf_sql_time to time", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_time")).toBe("time");
				});

				it("maps cf_sql_bit to boolean", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_bit")).toBe("boolean");
				});

				it("maps cf_sql_decimal to decimal", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_decimal")).toBe("decimal");
				});

				it("maps cf_sql_float to float", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_float")).toBe("float");
				});

				it("maps cf_sql_double to float", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_double")).toBe("float");
				});

				it("maps cf_sql_bigint to biginteger", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_bigint")).toBe("biginteger");
				});

				it("maps cf_sql_binary to binary", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_binary")).toBe("binary");
				});

				it("maps cf_sql_blob to binary", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_blob")).toBe("binary");
				});

				it("maps cf_sql_smallint to integer", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_smallint")).toBe("integer");
				});

				it("maps cf_sql_tinyint to integer", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_tinyint")).toBe("integer");
				});

				it("maps cf_sql_numeric to decimal", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_numeric")).toBe("decimal");
				});

				it("defaults unknown types to string", () => {
					expect(autoMigrator.$cfSqlTypeToMigrationType("cf_sql_unknown_type")).toBe("string");
				});

			});

			describe("$dbTypeToMigrationType", () => {

				it("maps varchar to string", () => {
					expect(autoMigrator.$dbTypeToMigrationType("varchar")).toBe("string");
				});

				it("maps int to integer", () => {
					expect(autoMigrator.$dbTypeToMigrationType("int")).toBe("integer");
				});

				it("maps text to text", () => {
					expect(autoMigrator.$dbTypeToMigrationType("text")).toBe("text");
				});

				it("maps datetime to datetime", () => {
					expect(autoMigrator.$dbTypeToMigrationType("datetime")).toBe("datetime");
				});

				it("maps timestamp to datetime", () => {
					expect(autoMigrator.$dbTypeToMigrationType("timestamp")).toBe("datetime");
				});

				it("maps boolean to boolean", () => {
					expect(autoMigrator.$dbTypeToMigrationType("boolean")).toBe("boolean");
				});

				it("maps decimal to decimal", () => {
					expect(autoMigrator.$dbTypeToMigrationType("decimal")).toBe("decimal");
				});

				it("maps float to float", () => {
					expect(autoMigrator.$dbTypeToMigrationType("float")).toBe("float");
				});

				it("maps bigint to biginteger", () => {
					expect(autoMigrator.$dbTypeToMigrationType("bigint")).toBe("biginteger");
				});

				it("maps blob to binary", () => {
					expect(autoMigrator.$dbTypeToMigrationType("blob")).toBe("binary");
				});

				it("returns unknown for unrecognized types", () => {
					expect(autoMigrator.$dbTypeToMigrationType("geometry_collection_xyz")).toBe("unknown");
				});

			});

			describe("diff()", () => {

				it("returns a struct with required keys", () => {
					local.result = autoMigrator.diff("Author");
					expect(local.result).toBeStruct();
					expect(local.result).toHaveKey("modelName");
					expect(local.result).toHaveKey("tableName");
					expect(local.result).toHaveKey("addColumns");
					expect(local.result).toHaveKey("removeColumns");
					expect(local.result).toHaveKey("changeColumns");
					expect(local.result.modelName).toBe("Author");
					expect(local.result.tableName).toBe("c_o_r_e_authors");
				});

				it("returns arrays for column changes", () => {
					local.result = autoMigrator.diff("Author");
					expect(local.result.addColumns).toBeArray();
					expect(local.result.removeColumns).toBeArray();
					expect(local.result.changeColumns).toBeArray();
				});

				it("excludes calculated properties from diff", () => {
					// The Author model has calculated property "numberofitems" with sql="..."
					// These should NOT appear in addColumns since they are virtual
					local.result = autoMigrator.diff("Author");
					local.addColumnNames = "";
					for (local.col in local.result.addColumns) {
						local.addColumnNames = ListAppend(local.addColumnNames, local.col.name);
					}
					expect(ListFindNoCase(local.addColumnNames, "numberofitems")).toBe(0);
				});

				it("does not flag primary key columns for removal", () => {
					local.result = autoMigrator.diff("Author");
					// The primary key "id" should never appear in removeColumns
					local.removeNames = "";
					for (local.col in local.result.removeColumns) {
						local.removeNames = ListAppend(local.removeNames, local.col.name);
					}
					expect(ListFindNoCase(local.removeNames, "id")).toBe(0);
				});

			});

			describe("diffAll()", () => {

				it("returns a struct", () => {
					local.result = autoMigrator.diffAll();
					expect(local.result).toBeStruct();
				});

				it("only includes models with actual differences", () => {
					local.result = autoMigrator.diffAll();
					// Each entry should have non-empty change arrays
					for (local.modelName in local.result) {
						local.d = local.result[local.modelName];
						local.hasChanges = ArrayLen(local.d.addColumns) > 0
							|| ArrayLen(local.d.removeColumns) > 0
							|| ArrayLen(local.d.changeColumns) > 0
							|| ArrayLen(local.d.renameColumns) > 0
							|| ArrayLen(local.d.suggestedRenames) > 0;
						expect(local.hasChanges).toBeTrue();
					}
				});

			});

			describe("generateMigrationCFC()", () => {

				it("produces valid CFC content with up and down methods", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [{name: "email", type: "string", nullable: true, "default": ""}],
						removeColumns: [{name: "legacy_field"}],
						changeColumns: [{name: "status", from: {type: "string"}, to: {type: "integer"}}]
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "update_test_models");

					expect(local.cfc).toInclude("extends=""wheels.migrator.Migration""");
					expect(local.cfc).toInclude("function up()");
					expect(local.cfc).toInclude("function down()");
				});

				it("generates addColumn in up for new columns", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [{name: "email", type: "string", nullable: true, "default": ""}],
						removeColumns: [],
						changeColumns: []
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "add_email");

					expect(local.cfc).toInclude('addColumn(table="test_models"');
					expect(local.cfc).toInclude('columnType="string"');
					expect(local.cfc).toInclude('columnName="email"');
				});

				it("generates removeColumn in down for new columns", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [{name: "email", type: "string", nullable: true, "default": ""}],
						removeColumns: [],
						changeColumns: []
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "add_email");

					// The down() should have removeColumn to reverse the addColumn
					expect(local.cfc).toInclude('removeColumn(table="test_models", columnName="email")');
				});

				it("generates removeColumn in up for dropped columns", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [],
						removeColumns: [{name: "legacy_field"}],
						changeColumns: []
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "remove_legacy");

					expect(local.cfc).toInclude('removeColumn(table="test_models", columnName="legacy_field")');
				});

				it("generates changeColumn in up for type changes", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [],
						removeColumns: [],
						changeColumns: [{name: "status", from: {type: "string"}, to: {type: "integer"}}]
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "change_status");

					expect(local.cfc).toInclude('changeColumn(table="test_models", columnName="status", columnType="integer")');
				});

				it("generates reverse changeColumn in down", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [],
						removeColumns: [],
						changeColumns: [{name: "status", from: {type: "string"}, to: {type: "integer"}}]
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "change_status");

					// down() should reverse: change back from integer to string
					expect(local.cfc).toInclude('changeColumn(table="test_models", columnName="status", columnType="string")');
				});

				it("handles empty diff with no-op comments", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [],
						removeColumns: [],
						changeColumns: []
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "no_changes");

					expect(local.cfc).toInclude("No changes detected");
				});

				it("includes migration name in the hint", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [],
						removeColumns: [],
						changeColumns: []
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "my_migration_name");

					expect(local.cfc).toInclude('hint="my_migration_name"');
				});

				it("generates allowNull attribute for addColumn", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [
							{name: "required_field", type: "string", nullable: false, "default": ""},
							{name: "optional_field", type: "string", nullable: true, "default": ""}
						],
						removeColumns: [],
						changeColumns: []
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "add_fields");

					expect(local.cfc).toInclude("allowNull=false");
					expect(local.cfc).toInclude("allowNull=true");
				});

				it("emits renameColumn in up() for each renameColumns entry", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [],
						removeColumns: [],
						changeColumns: [],
						renameColumns: [
							{from: "full_name", to: "fullName", type: "string", source: "hint"}
						],
						suggestedRenames: []
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "rename_name_field");
					expect(local.cfc).toInclude('renameColumn(table="test_models", columnName="full_name", newColumnName="fullName")');
				});

				it("emits reversed renameColumn in down() for each renameColumns entry", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [],
						removeColumns: [],
						changeColumns: [],
						renameColumns: [
							{from: "full_name", to: "fullName", type: "string", source: "hint"}
						],
						suggestedRenames: []
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "rename_name_field");
					// down() reverses: fullName -> full_name
					expect(local.cfc).toInclude('renameColumn(table="test_models", columnName="fullName", newColumnName="full_name")');
				});

				it("handles diff results without renameColumns key (backward compat)", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [{name: "bio", type: "text", nullable: true, "default": ""}],
						removeColumns: [],
						changeColumns: []
						// Note: no renameColumns key — simulate legacy callers
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "add_bio");
					expect(local.cfc).toInclude('addColumn(table="test_models"');
				});

				it("orders up() body as renames then adds then removes then changes", () => {
					local.diffResult = {
						modelName: "TestModel",
						tableName: "test_models",
						addColumns: [{name: "bio", type: "text", nullable: true, "default": ""}],
						removeColumns: [{name: "legacy"}],
						changeColumns: [{name: "status", from: {type: "string"}, to: {type: "integer"}}],
						renameColumns: [{from: "full_name", to: "fullName", type: "string", source: "hint"}],
						suggestedRenames: []
					};
					local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "mixed");
					local.renameAt = Find("renameColumn(", local.cfc);
					local.addAt = Find("addColumn(", local.cfc);
					local.removeAt = Find('removeColumn(table="test_models", columnName="legacy"', local.cfc);
					local.changeAt = Find("changeColumn(", local.cfc);
					expect(local.renameAt).toBeGT(0);
					expect(local.renameAt).toBeLT(local.addAt);
					expect(local.addAt).toBeLT(local.removeAt);
					expect(local.removeAt).toBeLT(local.changeAt);
				});

			});

			describe("diffAll() — rename integration", () => {

				it("accepts an options struct with per-model hints", () => {
					// Should not throw; models without matching adds/removes simply get no renames.
					local.result = autoMigrator.diffAll(options={
						hints: {"Author": {renames: {}}},
						heuristicThreshold: 0.7
					});
					expect(local.result).toBeStruct();
				});

				it("accepts an options struct with threshold only", () => {
					local.result = autoMigrator.diffAll(options={heuristicThreshold: 0.9});
					expect(local.result).toBeStruct();
				});

				it("is backward-compatible when called with no arguments", () => {
					local.result = autoMigrator.diffAll();
					expect(local.result).toBeStruct();
				});

				it("throws on an out-of-range heuristicThreshold instead of reporting no drift", () => {
					// Pre-fix, the per-model catch swallowed the InvalidThreshold
					// throw from every diff() call and diffAll() returned an empty
					// struct — silently reporting "no drift" for a config error.
					expect(() => {
						autoMigrator.diffAll(options = {heuristicThreshold: 5});
					}).toThrow("Wheels.InvalidThreshold");
				});

				it("rethrows invalid rename hints instead of silently skipping the model", () => {
					// Ensure the Author model is registered so diffAll() reaches it.
					g.model("Author");
					expect(() => {
						autoMigrator.diffAll(options = {
							hints: {"Author": {renames: {"no_such_column_xyz": "also_missing_xyz"}}}
						});
					}).toThrow("Wheels.InvalidRenameHint");
				});

			});

			describe("diff() — rename integration", () => {

				it("returns renameColumns and suggestedRenames keys in the result", () => {
					local.result = autoMigrator.diff("Author");
					expect(local.result).toHaveKey("renameColumns");
					expect(local.result).toHaveKey("suggestedRenames");
					expect(local.result.renameColumns).toBeArray();
					expect(local.result.suggestedRenames).toBeArray();
				});

				it("accepts options struct without breaking existing callers", () => {
					// Backward-compat: diff(modelName) with no options still works
					local.r1 = autoMigrator.diff("Author");
					local.r2 = autoMigrator.diff(modelName="Author", options={});
					expect(local.r1.tableName).toBe(local.r2.tableName);
				});

				it("threads heuristicThreshold through options", () => {
					// Threshold of 0.01 would make even unrelated pairs candidates.
					// We can't easily induce a rename without a real model mismatch, so
					// just verify the call doesn't explode.
					local.result = autoMigrator.diff(modelName="Author", options={heuristicThreshold: 0.01});
					expect(local.result).toHaveKey("renameColumns");
				});

			});

			describe("$sanitizeFileName", () => {

				it("lowercases input", () => {
					expect(autoMigrator.$sanitizeFileName("AddUserEmail")).toBe("adduseremail");
				});

				it("replaces spaces with underscores", () => {
					expect(autoMigrator.$sanitizeFileName("add user email")).toBe("add_user_email");
				});

				it("replaces special chars with underscores", () => {
					expect(autoMigrator.$sanitizeFileName("add;user/email")).toBe("add_user_email");
				});

				it("collapses consecutive underscores", () => {
					expect(autoMigrator.$sanitizeFileName("add___user")).toBe("add_user");
				});

				it("trims leading and trailing underscores", () => {
					expect(autoMigrator.$sanitizeFileName("__add_user__")).toBe("add_user");
				});

				it("returns 'migration' for empty input", () => {
					expect(autoMigrator.$sanitizeFileName("")).toBe("migration");
				});

				it("returns 'migration' for input that sanitizes to empty", () => {
					expect(autoMigrator.$sanitizeFileName("///")).toBe("migration");
				});

				it("preserves alphanumerics and underscores", () => {
					expect(autoMigrator.$sanitizeFileName("add_field_v2")).toBe("add_field_v2");
				});

			});

		});

	}

}
