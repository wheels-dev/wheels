/**
 * Regression coverage for `$renderDiffResult()` — the CLI printer for
 * `wheels migrate diff`.
 *
 * AutoMigrator returns add/remove/change/rename/suggest entries as
 * structs. Interpolating those structs (or nested `from`/`to` on
 * changeColumns) throws `Can't cast Complex Object Type [Struct] to
 * String`. The generate-auth User table is the live case: after
 * `wheels generate auth` + migrate on SQLite, User is a wall of
 * `changeColumns` whose `from`/`to` are `{type, size, scale, nullable}`.
 *
 * These specs feed that payload (and the other struct-shaped arrays)
 * through the renderer with no running app server.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("$renderDiffResult — generate-auth User payload", () => {

			it("prints User changeColumns without casting nested from/to structs", () => {
				// Shape AutoMigrator.diff("User") returns after `generate auth`
				// on SQLite: every string/datetime column is TEXT in the DB
				// (mapped to `text`) and cf_sql_varchar/`datetime` on the
				// model (mapped to `string`/`datetime`). #3565 tracks the
				// spurious type noise; this spec only pins the Struct cast.
				var parsed = {
					success: true,
					models: {
						User: $userShapedDiff()
					}
				};
				var cap = $newCapture();
				cap.$renderDiffResult(parsed, false);
				var output = cap.capturedOutput();

				expect(output).toInclude("--- User ---");
				expect(output).toInclude("  ~ change email (text -> string)");
				expect(output).toInclude("  ~ change passworddigest (text -> string)");
				expect(output).toInclude("  ~ change resettokendigest (text -> string)");
				expect(output).toInclude("  ~ change resettokenexpiresat (text -> datetime)");
				expect(output).toInclude("Preview only");
			});

			it("prints the same User payload from the single-model envelope", () => {
				var parsed = {
					success: true,
					model: $userShapedDiff()
				};
				var cap = $newCapture();
				cap.$renderDiffResult(parsed, false);
				expect(cap.capturedOutput()).toInclude("--- User ---");
				expect(cap.capturedOutput()).toInclude("  ~ change email (text -> string)");
			});

		});

		describe("$renderDiffResult — remaining struct arrays", () => {

			it("renders add/remove/rename/suggest from named fields, not the raw struct", () => {
				var parsed = {
					success: true,
					models: {
						User: {
							modelName: "User",
							tableName: "users",
							addColumns: [{name: "apiTokenDigest", type: "string", nullable: true, "default": ""}],
							removeColumns: [{name: "legacy_flag", type: "string"}],
							changeColumns: [],
							renameColumns: [{from: "full_name", to: "fullName", type: "string", source: "hint"}],
							suggestedRenames: [{
								from: "email_addr",
								to: "emailAddress",
								type: "string",
								confidence: 0.85,
								ambiguous: false
							}],
							unmappedColumns: [{name: "legacy_flag", type: "string"}]
						}
					}
				};
				var cap = $newCapture();
				cap.$renderDiffResult(parsed, false);
				var output = cap.capturedOutput();

				expect(output).toInclude("  + add    apiTokenDigest (string)");
				expect(output).toInclude("  - remove legacy_flag");
				expect(output).toInclude("--rename legacy_flag:newName");
				expect(output).toInclude("  ~ rename full_name -> fullName");
				expect(output).toInclude("  ? suggest email_addr -> emailAddress (0.85)");
			});

			it("does not crash when rename/suggest from/to are accidentally structs", () => {
				// Edge case: a changeColumn-shaped node lands in rename or
				// suggest (or Elvis returns the nested struct). The old
				// `#col.from#` / `suggestion.from ?: "?"` path cast-crashed.
				var parsed = {
					success: true,
					model: {
						modelName: "User",
						addColumns: [],
						removeColumns: [],
						changeColumns: [],
						renameColumns: [{
							from: {type: "text", size: 255, nullable: false},
							to: {type: "string", size: 255, nullable: false}
						}],
						suggestedRenames: [{
							from: {type: "text"},
							to: {name: "emailAddress", type: "string"},
							confidence: {value: 0.9}
						}]
					}
				};
				var cap = $newCapture();
				cap.$renderDiffResult(parsed, true);
				var output = cap.capturedOutput();

				expect(output).toInclude("--- User ---");
				expect(output).toInclude("  ~ rename");
				expect(output).toInclude("  ? suggest");
				expect(output).toInclude("Migration file(s) written.");
			});

			it("reports an in-sync payload without walking any column arrays", () => {
				var parsed = {
					success: true,
					models: {
						User: {
							modelName: "User",
							addColumns: [],
							removeColumns: [],
							changeColumns: [],
							renameColumns: [],
							suggestedRenames: []
						}
					}
				};
				var cap = $newCapture();
				cap.$renderDiffResult(parsed, false);
				expect(cap.capturedOutput()).toInclude("No differences found");
			});

		});

		describe("$stringifyDiffValue / $diffTypeLabel", () => {

			it("prefers a scalar name on a column struct and never stringifies the struct", () => {
				var cap = $newCapture();
				expect(cap.$stringifyDiffValue({name: "email", type: "string"})).toBe("email");
				expect(cap.$stringifyDiffValue("passwordDigest")).toBe("passwordDigest");
				expect(cap.$stringifyDiffValue({foo: {bar: 1}}, "?")).toBe("?");
			});

			it("reads type from a nested changeColumn from/to struct", () => {
				var cap = $newCapture();
				expect(cap.$diffTypeLabel({type: "text", size: 255, scale: 0, nullable: false})).toBe("text");
				expect(cap.$diffTypeLabel("string")).toBe("string");
				expect(cap.$diffTypeLabel({})).toBe("?");
			});

		});

	}

	private any function $newCapture() {
		return new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
	}

	/**
	 * User-shaped AutoMigrator payload after `generate auth` + migrate on
	 * SQLite. Mirrors cli/lucli/templates/auth/migration.txt columns.
	 */
	private struct function $userShapedDiff() {
		return {
			modelName: "User",
			tableName: "users",
			addColumns: [],
			removeColumns: [],
			changeColumns: [
				$change("email", "text", "string"),
				$change("passworddigest", "text", "string"),
				$change("resettokendigest", "text", "string"),
				$change("resettokenexpiresat", "text", "datetime"),
				$change("createdat", "text", "datetime"),
				$change("updatedat", "text", "datetime")
			],
			renameColumns: [],
			suggestedRenames: [],
			unmappedColumns: []
		};
	}

	private struct function $change(required string name, required string fromType, required string toType) {
		return {
			name: arguments.name,
			from: {type: arguments.fromType, size: 255, scale: 0, nullable: false},
			to: {type: arguments.toType, size: 255, scale: "", nullable: false}
		};
	}

}
