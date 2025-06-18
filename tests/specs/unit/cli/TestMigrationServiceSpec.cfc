component extends="tests.BaseSpec" {

	function run() {

		describe("TestMigrationService", () => {

			beforeEach(() => {
				variables.migrationService = new cli.models.TestMigrationService();
				variables.tempDir = getTempDirectory() & "test_migration_" & createUUID() & "/";
				directoryCreate(variables.tempDir);
			});

			afterEach(() => {
				if (directoryExists(variables.tempDir)) {
					directoryDelete(variables.tempDir, true);
				}
			});

			describe("Assertion Conversions", () => {

				it("should convert simple true assertions", () => {
					var input = 'assert("user.isActive()")';
					var result = migrationService.convertContent(input);
					expect(result.content).toInclude("expect(user.isActive()).toBeTrue()");
					expect(arrayLen(result.changes)).toBeGT(0);
				});

				it("should convert negated assertions", () => {
					var input = 'assert("!user.isActive()")';
					var result = migrationService.convertContent(input);
					expect(result.content).toInclude("expect(user.isActive()).toBeFalse()");
				});

				it("should convert equality assertions", () => {
					var testCases = [
						{input: 'assert("user.name == ''John''")', expected: "expect(user.name).toBe('John')"},
						{input: 'assert("count eq 5")', expected: "expect(count).toBe(5)"},
						{input: 'assert("total != 0")', expected: "expect(total).notToBe(0)"},
						{input: 'assert("value neq ""empty""")', expected: 'expect(value).notToBe("empty")'}
					];

					for (var testCase in testCases) {
						var result = migrationService.convertContent(testCase.input);
						expect(result.content).toInclude(testCase.expected);
					}
				});

				it("should convert comparison assertions", () => {
					var testCases = [
						{input: 'assert("count > 0")', expected: "expect(count).toBeGT(0)"},
						{input: 'assert("age gt 18")', expected: "expect(age).toBeGT(18)"},
						{input: 'assert("price < 100")', expected: "expect(price).toBeLT(100)"},
						{input: 'assert("score lt 50")', expected: "expect(score).toBeLT(50)"}
					];

					for (var testCase in testCases) {
						var result = migrationService.convertContent(testCase.input);
						expect(result.content).toInclude(testCase.expected);
					}
				});

				it("should convert type checking assertions", () => {
					var testCases = [
						{input: 'assert("isArray(results)")', expected: "expect(results).toBeArray()"},
						{input: 'assert("isStruct(data)")', expected: "expect(data).toBeStruct()"},
						{input: 'assert("isNumeric(price)")', expected: "expect(price).toBeNumeric()"}
					];

					for (var testCase in testCases) {
						var result = migrationService.convertContent(testCase.input);
						expect(result.content).toInclude(testCase.expected);
					}
				});

				it("should convert structKeyExists assertions", () => {
					var input = 'assert("structKeyExists(user, ''email'')")';
					var result = migrationService.convertContent(input);
					expect(result.content).toInclude('expect(user).toHaveKey("email")');
				});

				it("should convert length assertions", () => {
					var testCases = [
						{input: 'assert("len(password) == 8")', expected: "expect(password).toHaveLength(8)"},
						{input: 'assert("arrayLen(items) == 5")', expected: "expect(arrayLen(items)).toBe(5)"}
					];

					for (var testCase in testCases) {
						var result = migrationService.convertContent(testCase.input);
						expect(result.content).toInclude(testCase.expected);
					}
				});

				it("should convert contains assertions", () => {
					var input = 'assert("message contains ''error''")';
					var result = migrationService.convertContent(input);
					expect(result.content).toInclude("expect(message).toInclude('error')");
				});

				it("should handle complex assertions with warnings", () => {
					var complexCases = [
						'assert("user.isActive() and user.isVerified()")',
						'assert("count > 0 or isEmpty(items))")',
						'assert("evaluate(dynamicExpression)")'
					];

					for (var complexCase in complexCases) {
						var result = migrationService.convertContent(complexCase);
						expect(arrayLen(result.warnings)).toBeGT(0);
						expect(result.warnings[1]).toInclude("manual review recommended");
					}
				});

			});

			describe("Component Structure Conversion", () => {

				it("should convert extends attribute", () => {
					var input = 'component extends="tests.Test" {';
					var result = migrationService.convertContent(input);
					expect(result.content).toInclude('component extends="tests.BaseSpec" {');
				});

				it("should wrap test methods in describe/it blocks", () => {
					var input = 'function test_userValidation() {
						var user = model("User").new();
						assert("!user.valid()");
					}';
					
					var result = migrationService.convertContent(input);
					expect(result.content).toInclude("describe(");
					expect(result.content).toInclude("it(");
					expect(result.content).toInclude("should");
				});

				it("should convert lifecycle methods", () => {
					var lifecycleMethods = [
						{from: "function setup()", to: "beforeEach(() => {"},
						{from: "function teardown()", to: "afterEach(() => {"},
						{from: "function beforeTests()", to: "beforeAll(() => {"},
						{from: "function afterTests()", to: "afterAll(() => {"}
					];

					for (var method in lifecycleMethods) {
						var result = migrationService.convertContent(method.from);
						expect(result.content).toInclude(method.to);
					}
				});

			});

			describe("File Processing", () => {

				it("should process a single file", () => {
					var testFile = variables.tempDir & "TestModel.cfc";
					fileWrite(testFile, 'component extends="tests.Test" {
						function test_validation() {
							assert("model.valid()");
						}
					}');

					var result = migrationService.migrateFile(testFile);
					expect(result.success).toBeTrue();
					expect(fileExists(testFile)).toBeTrue();
					
					var content = fileRead(testFile);
					expect(content).toInclude("tests.BaseSpec");
					expect(content).toInclude("expect(model.valid()).toBeTrue()");
				});

				it("should create backup when requested", () => {
					var testFile = variables.tempDir & "TestBackup.cfc";
					var originalContent = 'component extends="tests.Test" { }';
					fileWrite(testFile, originalContent);

					var result = migrationService.migrateFile(testFile, true);
					expect(result.success).toBeTrue();
					
					var backupFile = testFile & ".bak";
					expect(fileExists(backupFile)).toBeTrue();
					expect(fileRead(backupFile)).toBe(originalContent);
				});

				it("should handle file read errors gracefully", () => {
					var nonExistentFile = variables.tempDir & "NonExistent.cfc";
					var result = migrationService.migrateFile(nonExistentFile);
					
					expect(result.success).toBeFalse();
					expect(result.error).toInclude("not found");
				});

				it("should skip non-CFC files", () => {
					var txtFile = variables.tempDir & "readme.txt";
					fileWrite(txtFile, "This is not a CFC file");
					
					var result = migrationService.migrateFile(txtFile);
					expect(result.skipped).toBeTrue();
					expect(result.reason).toInclude("Not a CFC file");
				});

			});

			describe("Directory Processing", () => {

				it("should process all CFC files in a directory", () => {
					// Create test files
					fileWrite(variables.tempDir & "Test1.cfc", 'component extends="tests.Test" { }');
					fileWrite(variables.tempDir & "Test2.cfc", 'component extends="tests.Test" { }');
					fileWrite(variables.tempDir & "readme.txt", "Not a CFC");

					var results = migrationService.migrateDirectory(variables.tempDir);
					
					expect(arrayLen(results)).toBe(2); // Only CFC files
					expect(results[1].success).toBeTrue();
					expect(results[2].success).toBeTrue();
				});

				it("should process subdirectories when recursive is true", () => {
					var subDir = variables.tempDir & "subdirectory/";
					directoryCreate(subDir);
					
					fileWrite(variables.tempDir & "Test1.cfc", 'component extends="tests.Test" { }');
					fileWrite(subDir & "Test2.cfc", 'component extends="tests.Test" { }');

					var results = migrationService.migrateDirectory(variables.tempDir, true, false);
					
					expect(arrayLen(results)).toBe(2);
				});

				it("should respect backup option for all files", () => {
					fileWrite(variables.tempDir & "Test1.cfc", 'component extends="tests.Test" { }');
					fileWrite(variables.tempDir & "Test2.cfc", 'component extends="tests.Test" { }');

					migrationService.migrateDirectory(variables.tempDir, false, true);
					
					expect(fileExists(variables.tempDir & "Test1.cfc.bak")).toBeTrue();
					expect(fileExists(variables.tempDir & "Test2.cfc.bak")).toBeTrue();
				});

			});

			describe("Dry Run Mode", () => {

				it("should not modify files in dry run mode", () => {
					var testFile = variables.tempDir & "DryRunTest.cfc";
					var originalContent = 'component extends="tests.Test" {
						function test_something() {
							assert("true");
						}
					}';
					fileWrite(testFile, originalContent);

					var result = migrationService.migrateFile(testFile, false, true);
					
					expect(result.success).toBeTrue();
					expect(result.dryRun).toBeTrue();
					expect(fileRead(testFile)).toBe(originalContent); // File unchanged
					expect(result.preview).toInclude("tests.BaseSpec"); // Preview shows changes
				});

			});

			describe("Statistics and Reporting", () => {

				it("should track conversion statistics", () => {
					migrationService.resetStatistics();
					
					// Process some files
					fileWrite(variables.tempDir & "Test1.cfc", 'component extends="tests.Test" {
						function test_one() { assert("true"); }
					}');
					fileWrite(variables.tempDir & "Test2.cfc", 'component { }'); // No changes needed
					fileWrite(variables.tempDir & "Test3.txt", 'Not a CFC'); // Skipped

					migrationService.migrateDirectory(variables.tempDir);
					
					var stats = migrationService.getStatistics();
					expect(stats.filesProcessed).toBe(3);
					expect(stats.filesConverted).toBe(1);
					expect(stats.filesSkipped).toBe(1);
				});

				it("should generate comprehensive report", () => {
					fileWrite(variables.tempDir & "TestReport.cfc", 'component extends="tests.Test" {
						function test_complex() {
							assert("a and b"); // Will generate warning
						}
					}');

					var results = migrationService.migrateDirectory(variables.tempDir);
					var report = migrationService.generateReport(results);
					
					expect(report).toHaveKey("summary");
					expect(report).toHaveKey("details");
					expect(report).toHaveKey("recommendations");
					expect(arrayLen(report.recommendations)).toBeGT(0);
				});

			});

			describe("Error Handling", () => {

				it("should provide specific error messages for conversion failures", () => {
					var malformedFile = variables.tempDir & "Malformed.cfc";
					fileWrite(malformedFile, 'component extends="tests.Test" {
						function test_broken() {
							assert(; // Syntax error
						}
					}');

					var result = migrationService.migrateFile(malformedFile);
					expect(result.success).toBeFalse();
					expect(result.error).toInclude("line");
				});

				it("should continue processing after individual file errors", () => {
					fileWrite(variables.tempDir & "Good.cfc", 'component extends="tests.Test" { }');
					fileWrite(variables.tempDir & "Bad.cfc", 'INVALID CFC CONTENT');
					fileWrite(variables.tempDir & "AlsoGood.cfc", 'component extends="tests.Test" { }');

					var results = migrationService.migrateDirectory(variables.tempDir);
					
					expect(arrayLen(results)).toBe(3);
					var successCount = 0;
					for (var result in results) {
						if (result.success) successCount++;
					}
					expect(successCount).toBe(2);
				});

			});

		});

	}

}