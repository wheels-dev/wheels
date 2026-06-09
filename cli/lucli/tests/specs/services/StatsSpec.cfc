component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.helpers = new cli.lucli.services.Helpers();
		variables.stats = new cli.lucli.services.Stats(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Stats Service", () => {

			describe("getStats()", () => {

				it("returns categories array with expected entries", () => {
					var data = stats.getStats();
					expect(arrayLen(data.categories)).toBe(7);

					var names = [];
					for (var cat in data.categories) {
						arrayAppend(names, cat.name);
					}
					expect(names).toInclude("Controllers");
					expect(names).toInclude("Models");
					expect(names).toInclude("Views");
				});

				it("returns totals with non-negative values", () => {
					var data = stats.getStats();
					expect(data.totals.files).toBeGTE(0);
					expect(data.totals.loc).toBeGTE(0);
					expect(data.totals.comments).toBeGTE(0);
					expect(data.totals.blanks).toBeGTE(0);
					expect(data.totals.total).toBeGTE(0);
				});

				it("total equals sum of categories", () => {
					var data = stats.getStats();
					var sumFiles = 0;
					for (var cat in data.categories) {
						sumFiles += cat.files;
					}
					expect(data.totals.files).toBe(sumFiles);
				});

				it("counts LOC correctly for a known file", () => {
					// Create a file with known content
					var testFile = tempRoot & "/app/models/StatsTestModel.cfc";
					directoryCreate(getDirectoryFromPath(testFile), true, true);
					fileWrite(testFile,
						'component extends="Model" {' & chr(10)
						& chr(10)
						& '	// this is a comment' & chr(10)
						& '	function config() {' & chr(10)
						& '	}' & chr(10)
						& chr(10)
						& '}'
					);

					var data = stats.getStats();
					// Find Models category
					var modelCat = {};
					for (var cat in data.categories) {
						if (cat.name == "Models") modelCat = cat;
					}
					// Should have at least 1 file and some LOC
					expect(modelCat.files).toBeGTE(1);
					expect(modelCat.loc).toBeGTE(3); // 3 code lines in our test file
					expect(modelCat.comments).toBeGTE(1); // 1 comment line
					expect(modelCat.blanks).toBeGTE(2); // 2 blank lines
				});

				it("returns topFiles sorted by line count descending", () => {
					var data = stats.getStats();
					if (arrayLen(data.topFiles) >= 2) {
						expect(data.topFiles[1].lines).toBeGTE(data.topFiles[2].lines);
					}
				});

			});

			describe("getNotes()", () => {

				it("finds TODO annotations", () => {
					// Create a file with a TODO
					var testFile = tempRoot & "/app/models/NotesTestModel.cfc";
					directoryCreate(getDirectoryFromPath(testFile), true, true);
					fileWrite(testFile,
						'component {' & chr(10)
						& '	// TODO: implement validation' & chr(10)
						& '	// FIXME: broken query' & chr(10)
						& '}'
					);

					var data = stats.getNotes();
					expect(data.total).toBeGTE(2);
					expect(arrayLen(data.annotations["TODO"])).toBeGTE(1);
					expect(arrayLen(data.annotations["FIXME"])).toBeGTE(1);

					// Check annotation has correct structure
					var todo = data.annotations["TODO"][1];
					expect(structKeyExists(todo, "file")).toBeTrue();
					expect(structKeyExists(todo, "line")).toBeTrue();
					expect(structKeyExists(todo, "text")).toBeTrue();
				});

				it("finds custom annotation types", () => {
					var testFile = tempRoot & "/app/controllers/NotesTestController.cfc";
					directoryCreate(getDirectoryFromPath(testFile), true, true);
					fileWrite(testFile,
						'component {' & chr(10)
						& '	// HACK: temporary workaround' & chr(10)
						& '}'
					);

					var data = stats.getNotes(annotations = "TODO", custom = "HACK");
					expect(arrayLen(data.annotations["HACK"])).toBeGTE(1);
					expect(data.annotations["HACK"][1].text).toInclude("temporary");
				});

				it("returns zero total when no annotations exist", () => {
					// Create clean file
					var testFile = tempRoot & "/app/models/CleanModel.cfc";
					directoryCreate(getDirectoryFromPath(testFile), true, true);
					fileWrite(testFile, 'component {}');

					// Use a custom annotation type unlikely to exist
					var data = stats.getNotes(annotations = "XYZNONEXISTENT");
					expect(data.annotations["XYZNONEXISTENT"]).toBeEmpty();
				});

				it("ignores annotations in string literals and identifier suffixes — only comments count (##M11)", () => {
					var testFile = tempRoot & "/app/models/NotesFalsePositive.cfc";
					directoryCreate(getDirectoryFromPath(testFile), true, true);
					fileWrite(testFile,
						'component {' & chr(10)
						& '	// QUIRK: this is a real annotation' & chr(10)
						& '	var note = "QUIRK: fake one inside a string literal";' & chr(10)
						& '	var methodQUIRK = 1;' & chr(10)
						& '}'
					);

					// Scan only QUIRK so other fixture files don't interfere. Only the
					// real `// QUIRK` comment must count — not the string literal, not
					// the `methodQUIRK` identifier suffix.
					var data = stats.getNotes(annotations = "QUIRK");
					expect(arrayLen(data.annotations["QUIRK"])).toBe(1);
					expect(data.annotations["QUIRK"][1].text).toInclude("real");
				});

			});

		});

	}

}
